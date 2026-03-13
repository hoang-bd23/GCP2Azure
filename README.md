# GCP Landing Zone - Terraform

Deploy a GCP Landing Zone with Shared VPC (hub-and-spoke), hybrid IPsec VPN to Azure, centralized observability, and separate Dev/Prod environments.

## 📑 Mục lục (Table of Contents)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Deployment Order](#deployment-order)
- [Prerequisites](#prerequisites)
- [Hướng dẫn thiết lập từ đầu (Getting Started Guide)](#hướng-dẫn-thiết-lập-từ-đầu-getting-started-guide)
- [Quick Start (cho người đã hiểu)](#quick-start-cho-người-đã-hiểu)
- [Troubleshooting — Các lỗi thường gặp và cách sửa](#troubleshooting--các-lỗi-thường-gặp-và-cách-sửa)
- [Tổng hợp: Các quyền cần cấp trước khi bắt đầu](#tổng-hợp-các-quyền-cần-cấp-trước-khi-bắt-đầu)
- [Tiết kiệm chi phí — Xóa tài nguyên tốn phí](#tiết-kiệm-chi-phí--xóa-tài-nguyên-tốn-phí-giữ-lại-phần-miễn-phí)
- [Hybrid VPN — GCP ↔ Azure](#hybrid-vpn--gcp--azure)

## Architecture

- **Shared VPC** (`prj-hub-network`) with Dev (`10.10.0.0/16`) and Prod (`10.20.0.0/16`) subnets
- **HA Cloud VPN** with IPsec/IKEv2 tunnel to Azure VPN Gateway (optional)
- **Centralized Observability** (`prj-central-observability`) with Log Router, BigQuery, Pub/Sub, Cloud Functions
- **Dev/Prod Service Projects** attached to Shared VPC with VMs and Ops Agent

## Directory Structure

```
landingzone_gcp/
├── foundation/              # Infrastructure Foundation (Shared)
│   ├── 00-bootstrap/        # Seed project, state bucket, TF service account
│   ├── 01-org/              # Folders, projects, APIs, org policies
│   ├── 02-security/         # KMS, SCC, IAM
│   ├── 03-network-hub/      # Shared VPC, VPN, NAT, Router, Firewall, LB
│   └── 04-observability/    # Logging, monitoring, BigQuery, Pub/Sub, CF
├── environments/            # Workload Environments
│   ├── dev/                 # Dev service project + VM
│   └── prod/                # Prod service project + VM
├── azure/                   # Azure hybrid VPN (optional)
├── modules/
│   ├── project/             # GCP project creation
│   ├── vpc/                 # VPC, subnets
│   ├── firewall/            # Firewall rules
│   ├── vpn/                 # HA VPN, Cloud Router, BGP
│   ├── nat/                 # Cloud NAT
│   ├── loadbalancer/        # External HTTP(S) LB
│   ├── compute/             # VM instances with Ops Agent
│   ├── observability/       # Logging, monitoring, Pub/Sub, BigQuery
│   └── security/            # KMS, SCC
├── scripts/
│   ├── deploy.ps1           # Automated deployment script
│   └── destroy-paid.ps1     # Selective destroy (paid resources only)
└── data/
    └── new8.xml             # Architecture diagram (draw.io)
```

## Deployment Order

```
(Foundation)                                (Workloads)
00-bootstrap → 01-org → 02-security → 03-network-hub → 04-observability
                                            │                
                                            ├── environments/dev
                                            ├── environments/prod
                                            └── azure/ (optional)
```

---

## Prerequisites

- GCP Organization (có Cloud Identity hoặc Google Workspace)
- Billing account đã kích hoạt
- `gcloud` CLI đã cài đặt
- Terraform >= 1.5.0
- Account có quyền **Organization Admin** trên GCP org

### Các quyền cần thiết trên Organization

Account của bạn cần những role sau trên **Organization level**. Nếu thiếu, sẽ gặp lỗi 403 khi apply:

| Role | Dùng cho | Lệnh cấp quyền |
|------|----------|-----------------|
| `roles/resourcemanager.organizationAdmin` | Quản lý org | Mặc định có nếu là Super Admin |
| `roles/resourcemanager.projectCreator` | Tạo project | `gcloud organizations add-iam-policy-binding <ORG_ID> --member="user:<EMAIL>" --role="roles/resourcemanager.projectCreator"` |
| `roles/resourcemanager.folderCreator` | Tạo folder | Tương tự, thay role |
| `roles/billing.user` | Gán billing vào project | Cấp trên **billing account** (xem mục 5) |
| `roles/compute.xpnAdmin` | Bật Shared VPC | Cấp trên org |
| `roles/orgpolicy.policyAdmin` | Tạo org policy | Cấp trên org |

---

## Hướng dẫn thiết lập từ đầu (Getting Started Guide)

### 1. Xác thực Google Cloud

Terraform **không dùng** `gcloud auth login` — nó dùng **Application Default Credentials (ADC)**. Bạn cần chạy **cả hai** lệnh:

```bash
# Đăng nhập gcloud CLI (dùng cho lệnh gcloud)
gcloud auth login

# Đăng nhập ADC (dùng cho Terraform) — BẮT BUỘC
gcloud auth application-default login
```

> **⚠️ Quan trọng:** Nếu chỉ chạy `gcloud auth login` mà KHÔNG chạy `gcloud auth application-default login`, Terraform sẽ KHÔNG xác thực được → lỗi 403 ở mọi resource.

> **Lưu ý:** Nếu `gcloud auth application-default login` mở trình duyệt sai tài khoản, dùng flag `--no-launch-browser` để lấy URL thủ công và mở trên trình duyệt đúng profile.

### 2. Thiết lập ADC Quota Project

Sau khi tạo xong seed project (layer 00), **bắt buộc** phải set quota project cho ADC. Nếu không, các API như `orgpolicy.googleapis.com` sẽ lỗi:

```bash
gcloud auth application-default set-quota-project <SEED_PROJECT_ID>
```

Nếu thiếu bước này, bạn sẽ gặp lỗi:
```
Error 403: Your application is authenticating by using local Application Default Credentials.
The orgpolicy.googleapis.com API requires a quota project, which is not set by default.
```

**Ngoài ra**, cần enable API `orgpolicy.googleapis.com` trên seed project:
```bash
gcloud services enable orgpolicy.googleapis.com --project=<SEED_PROJECT_ID>
```

### 3. Lấy thông tin cần thiết

Bạn **không cần** có sẵn project nào. Chỉ cần 2 thông tin **đã tồn tại** trên GCP:

```bash
# Lấy Organization ID
gcloud organizations list
# → Ghi lại cột ID (dạng số, ví dụ: 614651398366)

# Lấy Billing Account ID
gcloud billing accounts list
# → Ghi lại cột ACCOUNT_ID (dạng XXXXXX-XXXXXX-XXXXXX)
```

### 4. Chọn tên Project ID (phải unique toàn cầu)

Project ID trên GCP phải **duy nhất trên toàn thế giới**. Đặt tên theo pattern:

```
<mục-đích>-<tên-tổ-chức>
```

Ví dụ:
| Mục đích | Project ID |
|----------|------------|
| Bootstrap (seed) | `lz-bootstrap-myorg` |
| Hub Network | `prj-hub-net-myorg` |
| Observability | `prj-obs-myorg` |
| Dev | `prj-dev-myorg` |
| Prod | `prj-prod-myorg` |

### 5. Kiểm tra quyền Billing

Account cần role **Billing Account User** (`roles/billing.user`) trên **billing account** (không phải org). Kiểm tra:

```bash
gcloud billing accounts get-iam-policy <BILLING_ACCOUNT_ID>
```

Nếu không thấy account trong danh sách, nhờ billing admin cấp:
```bash
gcloud billing accounts add-iam-policy-binding <BILLING_ACCOUNT_ID> \
  --member="user:your-email@example.com" \
  --role="roles/billing.user"
```

### 6. Tạo file terraform.tfvars và deploy

```bash
cd environments/00-bootstrap
cp terraform.tfvars.example terraform.tfvars
# Sửa terraform.tfvars với giá trị thực (org_id, billing_account, project IDs...)

terraform init
terraform apply
```

> **Backend cho các layer sau (01-07):** Các layer 01 trở đi dùng GCS remote backend. Khi `terraform init`, cần truyền bucket name:
> ```bash
> terraform init "-backend-config=bucket=<TF_STATE_BUCKET_NAME>"
> ```

---

## Quick Start (cho người đã hiểu)

```bash
# 0. Xác thực
gcloud auth login
gcloud auth application-default login

# 1. Bootstrap — tạo seed project, state bucket, TF SA
cd environments/00-bootstrap
cp terraform.tfvars.example terraform.tfvars   # Sửa giá trị
terraform init
terraform apply

# Set quota project cho ADC (sau khi 00-bootstrap xong)
gcloud auth application-default set-quota-project <SEED_PROJECT_ID>
gcloud services enable orgpolicy.googleapis.com --project=<SEED_PROJECT_ID>

# 2. Organization — folders, projects, org policies
cd ../01-org
cp terraform.tfvars.example terraform.tfvars
terraform init "-backend-config=bucket=<TF_STATE_BUCKET>"
terraform apply

# 3. Tiếp tục theo thứ tự: 02 → 03 → 04 → 05/06 → 07 (optional)
# Mỗi layer: cp terraform.tfvars.example terraform.tfvars → sửa → init → apply
```

---

## Troubleshooting — Các lỗi thường gặp và cách sửa

### Lỗi 1: Billing permission denied

```
Error: failed pre-requisites: missing permission on "billingAccounts/...": billing.resourceAssociations.create
```

**Nguyên nhân:** Account chưa có quyền `roles/billing.user` trên billing account.

**Cách sửa:**
```bash
gcloud billing accounts add-iam-policy-binding <BILLING_ACCOUNT_ID> \
  --member="user:<YOUR_EMAIL>" \
  --role="roles/billing.user"
```

---

### Lỗi 2: Billing quota exceeded

```
Error: Precondition check failed — Cloud billing quota exceeded
```

**Nguyên nhân:** Free tier / trial billing account giới hạn số project được gán billing (thường 3-5 project).

**Cách sửa:**
- Yêu cầu tăng quota tại: https://support.google.com/code/contact/billing_quota_increase
- Hoặc nâng billing account lên paid tier
- Nếu chỉ cần test: xóa bớt project không dùng để giải phóng quota

---

### Lỗi 3: ADC chưa đăng nhập / hết hạn

```
Error 403: The caller does not have permission, forbidden
```

(Dù đã chạy `gcloud auth login` và có đủ role)

**Nguyên nhân:** Terraform dùng **ADC**, không dùng gcloud credentials. ADC chưa đăng nhập hoặc đã hết hạn.

**Cách sửa:**
```bash
# Kiểm tra account nào đang active
gcloud auth list

# Đăng nhập lại ADC
gcloud auth application-default login

# Nếu cần chỉ định account cụ thể
gcloud auth application-default login --no-launch-browser
```

---

### Lỗi 4: Org Policy API thiếu quota project

```
Error 403: The orgpolicy.googleapis.com API requires a quota project, which is not set by default.
```

**Nguyên nhân:** ADC cần biết project nào chịu quota cho API call. Mặc định không có.

**Cách sửa:**
```bash
# Set quota project (chạy SAU khi 00-bootstrap tạo xong seed project)
gcloud auth application-default set-quota-project <SEED_PROJECT_ID>

# Enable orgpolicy API trên project đó
gcloud services enable orgpolicy.googleapis.com --project=<SEED_PROJECT_ID>
```

> **Lưu ý:** Code đã cấu hình `user_project_override = true` và `billing_project` trong provider.tf của các layer 01-06, nhưng lần đầu cần set quota project thủ công.

---

### Lỗi 5: Org Policy sai loại constraint (boolean vs list)

```
Error: Policy and Constraint must be of the same type
```

**Nguyên nhân:** Constraint `compute.vmExternalIpAccess` là **list** constraint, không phải boolean. Dùng `enforce = "TRUE"` là sai.

**Cách sửa:** Dùng `deny_all = "TRUE"` thay vì `enforce = "TRUE"`:
```hcl
# ❌ Sai — cho list constraint
spec {
  rules {
    enforce = "TRUE"
  }
}

# ✅ Đúng — deny_all cho list constraint
spec {
  rules {
    deny_all = "TRUE"
  }
}
```

> **Mẹo:** Kiểm tra loại constraint: `gcloud org-policies describe <CONSTRAINT> --organization=<ORG_ID>`. Nếu thấy `constraintType: ListConstraint` → dùng `allow_all`/`deny_all`. Nếu `BooleanConstraint` → dùng `enforce`.

---

### Lỗi 6: Org Policy permission denied

```
Error: Permission 'orgpolicy.policies.create' denied on resource 'organizations/...'
```

**Nguyên nhân:** Account chưa có `roles/orgpolicy.policyAdmin` trên org.

**Cách sửa:**
```bash
gcloud organizations add-iam-policy-binding <ORG_ID> \
  --member="user:<YOUR_EMAIL>" \
  --role="roles/orgpolicy.policyAdmin"
```

---

### Lỗi 7: Shared VPC enableXpnHost permission

```
Error: Required 'compute.organizations.enableXpnHost' permission for 'projects/...'
```

**Nguyên nhân:** Account chưa có `roles/compute.xpnAdmin` trên org.

**Cách sửa:**
```bash
gcloud organizations add-iam-policy-binding <ORG_ID> \
  --member="user:<YOUR_EMAIL>" \
  --role="roles/compute.xpnAdmin"
```

---

### Lỗi 8: Cannot destroy project (deletion_policy = PREVENT)

```
Error: Cannot destroy project as deletion_policy is set to PREVENT.
```

**Nguyên nhân:** Google provider mặc định bảo vệ project khỏi bị xóa. Code đã cấu hình `deletion_policy = "DELETE"`, nhưng nếu project tạo trước khi thêm setting này, state vẫn lưu giá trị cũ.

**Cách sửa:**
```bash
# Bước 1: Apply trước để cập nhật deletion_policy trong state
terraform apply "-target=google_project.seed" -auto-approve

# Bước 2: Giờ mới destroy được
terraform destroy
```

> **⚠️ PowerShell:** Bắt buộc đặt dấu `"` quanh `-target=...`:
> ```powershell
> # ✅ Đúng (PowerShell)
> terraform apply "-target=google_project.seed"
>
> # ❌ Sai (PowerShell tách thành 2 argument)
> terraform apply -target=google_project.seed
> ```

---

### Lỗi 9: Project already exists (sau khi xóa rồi tạo lại)

```
Error: googleapi: Error 409: Requested entity already exists, alreadyExists
```

**Nguyên nhân:** GCP không xóa project ngay mà đưa vào **"pending deletion"** 30 ngày. Không thể tạo project mới cùng ID.

**Cách sửa:**
```bash
# Bước 1: Khôi phục project
gcloud projects undelete <PROJECT_ID>

# Bước 2: Import vào Terraform state
terraform import google_project.seed <PROJECT_ID>
# Hoặc cho module:
terraform import module.dev_project.google_project.this <PROJECT_ID>

# Bước 3: Apply bình thường
terraform apply
```

---

### Lỗi 10: Service account does not exist (Shared VPC subnet IAM)

```
Error: Service account <PROJECT_ID>@cloudservices.gserviceaccount.com does not exist
```

**Nguyên nhân:** Google APIs Service Agent SA dùng format `<PROJECT_NUMBER>@cloudservices.gserviceaccount.com` (số), không phải `<PROJECT_ID>@cloudservices.gserviceaccount.com` (text).

**Cách sửa:** Code đã fix bằng `data "google_project"` để lấy project number tự động:
```hcl
data "google_project" "dev" {
  project_id = var.dev_project_id
}

resource "google_compute_subnetwork_iam_member" "dev_subnet_user" {
  # ...
  member = "serviceAccount:${data.google_project.dev.number}@cloudservices.gserviceaccount.com"
}
```

---

### Lỗi 11: Log sink service account chưa propagate

```
Error: Service account service-org-<ORG_ID>@gcp-sa-logging.iam.gserviceaccount.com does not exist
```

**Nguyên nhân:** Khi tạo org-level log sink, GCP tự động tạo một service account, nhưng cần vài chục giây để propagate. Nếu IAM binding tạo quá nhanh → SA chưa sẵn sàng.

**Cách sửa:** Chạy lại `terraform apply` sau 30 giây:
```bash
# Đợi propagation rồi apply lại
sleep 30   # Linux/Mac
Start-Sleep -Seconds 30   # PowerShell

terraform apply
```

---

### Lỗi 12: PowerShell xử lý sai argument với dấu `=`

Nhiều lệnh Terraform dùng `=` trong argument. PowerShell xử lý khác Bash.

**Quy tắc chung trên PowerShell:**
```powershell
# Backend config
terraform init "-backend-config=bucket=my-bucket"

# Target resource
terraform apply "-target=google_project.seed"

# Import
terraform import module.dev_project.google_project.this prj-dev-myorg
```

---

## Tổng hợp: Các quyền cần cấp trước khi bắt đầu

Chạy tất cả lệnh dưới đây **một lần** trước khi deploy để tránh lỗi quyền:

```bash
ORG_ID="<your_org_id>"
EMAIL="<your_email>"
BILLING_ID="<your_billing_account_id>"

# Org-level roles
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$EMAIL" --role="roles/resourcemanager.organizationAdmin"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$EMAIL" --role="roles/resourcemanager.projectCreator"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$EMAIL" --role="roles/resourcemanager.folderCreator"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$EMAIL" --role="roles/compute.xpnAdmin"

gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:$EMAIL" --role="roles/orgpolicy.policyAdmin"

# Billing role (trên billing account, không phải org)
gcloud billing accounts add-iam-policy-binding $BILLING_ID \
  --member="user:$EMAIL" --role="roles/billing.user"
```

> **PowerShell version** (thay `$` bằng biến PS):
> ```powershell
> $ORG_ID = "<your_org_id>"
> $EMAIL = "<your_email>"
> $BILLING_ID = "<your_billing_account_id>"
>
> gcloud organizations add-iam-policy-binding $ORG_ID `
>   "--member=user:$EMAIL" "--role=roles/resourcemanager.organizationAdmin"
> # ... tương tự cho các role khác
> ```

---

## Tiết kiệm chi phí — Xóa tài nguyên tốn phí, giữ lại phần miễn phí

Khi không cần chạy workload (ví dụ: ngưng lab, nghỉ cuối tuần), bạn có thể **xóa chọn lọc** các tài nguyên mất phí mà vẫn giữ nguyên hạ tầng nền (VPC, firewall, IAM, org structure...) để khi cần chỉ `terraform apply` lại là xong.

### Tài nguyên MẤT PHÍ khi tồn tại (kể cả không dùng)

| Tài nguyên | Layer | Ước tính/tháng |
|---|---|---|
| Dev VM (e2-micro + boot disk) | 05-env-dev | ~$7 |
| Prod VM (e2-micro + boot disk) | 06-env-prod | ~$7 |
| Cloud NAT gateway | 03-network-hub | ~$32 |
| GCP HA VPN Gateway (Tùy chọn) | 03-network-hub | ~$50 - $70 |
| Azure VPN Gateway VpnGw1 | azure/ | ~$140 |
| KMS keys (2 keys) | 02-security | ~$0.12 |
| **Tổng** | | **~$250/tháng (nếu chạy VPN 24/7)** |

*(Lưu ý: VPN Gateway của Azure và GCP có chi phí duy trì hàng tháng khá cao. Vì đây là Lab, nếu dự định vài ngày tới không test, bạn nên xóa hẳn Gateway đi).*

### Tài nguyên MIỄN PHÍ (giữ lại an toàn)

| Tài nguyên | Layer |
|---|---|
| Seed project, GCS state bucket, TF service account | 00-bootstrap |
| 3 Folders, 4 Projects, Org Policies, APIs | 01-org |
| KMS keyring (chỉ key mất phí, keyring miễn phí) | 02-security |
| VPC, 2 Subnets, 5 Firewall rules, Cloud Router, Shared VPC | 03-network-hub |
| Azure VNet, NSG, Resource Group | azure/ |
| Monitoring dashboard, alerts, log sinks, empty datasets | 04-observability |

### Lệnh xóa theo thứ tự (Sử dụng Automation Script)

Thay vì gõ từng lệnh thủ công, dự án đã cung cấp sẵn script tự động dọn dẹp môi trường tốn tiền chỉ bằng 1 câu lệnh:

Mở PowerShell tại thư mục gốc của dự án (`F:\DEVOPS\landingzone_gcp`):

```powershell
# CÁCH 1: Xóa máy ảo và NAT (Tiết kiệm ~50$/tháng)
# Lệnh này giữ lại hệ thống VPN để lần sau test không phải đợi lâu.
# Tài nguyên bị xóa: VM Dev/Prod, GCP NAT, Load Balancer
.\scripts\destroy-paid.ps1

# CÁCH 2: Xóa TOÀN BỘ tài nguyên tốn phí (Tiết kiệm ~250$/tháng)
# Lệnh này xóa sạch sành sanh những gì phát sinh tiền, bao gồm cả VPN của Azure và GCP.
# Tài nguyên bị xóa: VM Dev/Prod, GCP NAT, Load Balancer, Azure VPN Gateway, GCP HA VPN Gateway
.\scripts\destroy-paid.ps1 -IncludeAzure
```

### CÁCH 3: Xóa thủ công từng bước (Manual Destroy)

Nếu bạn không muốn dùng Script và muốn tự tay kiểm soát quá trình xóa, hãy thực hiện theo đúng thứ tự sau để tránh lỗi phụ thuộc (dependency):

**Bước 1: Xóa các môi trường Workload (dev & prod)**
```powershell
cd f:\DEVOPS\landingzone_gcp\environments\prod
terraform destroy -auto-approve

cd ..\dev
terraform destroy -auto-approve
```

**Bước 2: Xóa tài nguyên Azure (Nếu có)**
```powershell
cd f:\DEVOPS\landingzone_gcp\azure
terraform destroy -auto-approve
```

**Bước 3: Xóa chọn lọc tại Foundation (03-network-hub)**
*Lưu ý: Tại đây ta chỉ xóa Gateway, không xóa Network.*
```powershell
cd f:\DEVOPS\landingzone_gcp\foundation\03-network-hub

# Xóa NAT
terraform destroy -target=module.nat -auto-approve

# Xóa Load Balancer
terraform destroy -target=module.loadbalancer -auto-approve

# Xóa HA VPN Gateway (Nếu muốn tiết kiệm thêm 50-70$/tháng)
terraform destroy -target=module.vpn -auto-approve
```

**Bước 4: Kiểm tra lại (Optional)**
Check xem còn sót resource nào không:
```powershell
terraform state list
```


*⚠️ Lưu ý: Nếu bạn xóa VPN Gateway, quá trình tạo lại (`deploy`) vào lần sau sẽ mất khoảng 30-45 phút do giới hạn tốc độ khởi tạo phần cứng của Azure. Đồng thời khi GCP tạo lại VPN Gateway mới, Public IP của HA VPN GCP có thể bị đổi, bạn sẽ cần lấy 2 IP mới đó cập nhật số vào tệp `azure/terraform.tfvars` trước khi apply Azure.*

### Khi cần deploy lại kiến trúc nguyên trạng

Chạy script deploy cấp tốc khối mạng và máy chủ để dựng lại Lab:

```powershell
.\scripts\deploy.ps1 -StartFrom 3
```
*(Cả quy trình kết nối VPN, Máy ảo hai bên sẽ tự động được tạo ra lại đúng chỗ cũ chờ bạn test).*

### Deploy thủ công (Manual Deployment)

Trong trường hợp bạn muốn dựng lại từng lớp để quan sát quá trình khởi tạo, hãy chạy theo thứ tự sau:

**Bước 1: Khắc phục/Dựng lại Foundation (03-network-hub)**
*(Lệnh này sẽ tạo lại NAT, VPN Gateway và Load Balancer nếu đã bị xóa trước đó)*
```powershell
cd f:\DEVOPS\landingzone_gcp\foundation\03-network-hub
terraform apply -auto-approve
```

**Bước 2: Cập nhật thông số VPN (NẾU CÓ THAY ĐỔI)**
*Nếu bạn vừa tạo mới lại HA VPN Gateway ở bước 1, hãy kiểm tra lại 2 địa chỉ Public IP mới của GCP tại Console và cập nhật vào file:*
- File: `f:\DEVOPS\landingzone_gcp\azure\terraform.tfvars` (Biến `gcp_vpn_gateway_ips`)

**Bước 3: Dựng hạ tầng Azure**
```powershell
cd f:\DEVOPS\landingzone_gcp\azure
terraform apply -auto-approve
```

**Bước 4: Dựng lại các môi trường Workload (dev & prod)**
```powershell
cd f:\DEVOPS\landingzone_gcp\environments\dev
terraform apply -auto-approve

cd ..\prod
terraform apply -auto-approve
```

---

## Hybrid VPN — GCP ↔ Azure

Layer `07-hybrid-vpn` thiết lập kết nối IPsec/IKEv2 **HA (High Availability) 2-tunnel** giữa GCP Cloud VPN và Azure VPN Gateway, sử dụng BGP để trao đổi route động.

### Kiến trúc

```
GCP (prj-hub-net-buiduchoang)          Azure (rg-hybrid-vpn)
────────────────────────────           ─────────────────────────────────
hub-ha-vpn-gateway                     azure-vpn-gateway
  interface 0: 34.152.104.244  ──┐       PIP: 20.212.156.210
  interface 1: 35.220.24.218   ──┼──── 2 × IPsec/IKEv2 tunnels
                                 └──── IKEv2 + AES-256 + SHA-256
hub-cloud-router (ASN 65001)           azure-vpn-gateway (ASN 65010)
  BGP peer tunnel-0: 169.254.21.1 ───── BGP peer: 169.254.21.2
  BGP peer tunnel-1: 169.254.22.1 ───── BGP peer: 169.254.22.2

Advertised routes:
  GCP → Azure: 10.10.0.0/16 (dev), 10.20.0.0/16 (prod)
  Azure → GCP: 10.30.0.0/16 (azure-vnet)

Test VMs:
  GCP dev-vm  : 10.10.1.5
  GCP prod-vm : 10.20.1.5
  Azure vm    : 10.30.1.5
```

### Thông số kết nối cuối cùng

| Tham số | Giá trị thực tế |
|---|---|
| GCP HA VPN interface 0 IP | `34.152.104.244` |
| GCP HA VPN interface 1 IP | `35.220.24.218` |
| Azure VPN Gateway Public IP | `4.193.139.46` |
| GCP BGP ASN | `65001` |
| Azure BGP ASN | `65010` |
| Tunnel-0 BGP (GCP ↔ Azure) | `169.254.21.1` ↔ `169.254.21.2` |
| Tunnel-1 BGP (GCP ↔ Azure) | `169.254.22.1` ↔ `169.254.22.2` |
| Shared Secret | `AzureGCP123!` |
| Mấu chốt kỹ thuật BGP | Azure dùng chung IP APIPA BGP (`169.254.21.2`) để GCP tunnel-0 có thể thiết lập trạng thái UP (`ESTABLISHED`) |

### Hướng dẫn test kết nối 2 chiều chi tiết

Sau khi Terraform triển khai xong toàn bộ hạ tầng trên cả 2 Cloud, kết nối ICMP (Ping) và SSH đã được cho phép qua các lớp Firewall của GCP (VPC Firewall) và Azure (NSG). 

Để kiểm tra network routing qua đường hầm VPN, làm theo các bước sau:

#### 1. Test từ nhánh GCP ➞ nhánh Azure

Sử dụng Google Cloud Shell hoặc Windows Terminal có cài [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/docs/install) đã đăng nhập. Lệnh này sử dụng IAP Tunnel để SSH vào máy ảo Private trong GCP, sau đó từ máy ảo Private đó ping trực tiếp sang máy ảo Private của Azure (`10.30.1.5`).

```powershell
# Từ nhánh Development (VPC Subnet 10.10.x.x)
gcloud compute ssh dev-vm --zone=asia-southeast1-b --project=prj-dev-buiduchoang --tunnel-through-iap --command="ping -c 4 10.30.1.5"

# Từ nhánh Production (VPC Subnet 10.20.x.x)
gcloud compute ssh prod-vm --zone=asia-southeast1-b --project=prj-prod-buiduchoang --tunnel-through-iap --command="ping -c 4 10.30.1.5"
```
**Kết quả kỳ vọng:** `0% packet loss` (nghĩa là gói tin ICMP đã được chuyển tiếp thành công từ VPC dev/prod sang hub-vpc, qua tunnel VPN gateway, tới subnet default của VNet bên Azure).

#### 2. Test từ nhánh Azure ➞ nhánh GCP

Không giống như GCP có IAP, Test VM của Azure được đặt trong Subnet riêng không có IP Public và Azure mặc định không cấu hình Bastion cho bài lab để tiết kiệm chi phí. Ta sẽ dùng tính năng **Run command** của Azure VNet để yêu cầu Azure Agent bên trong VM tự chạy lệnh ping và trả kết quả về bảng điều khiển.

Mở Windows Terminal chạy Azure CLI (`az login` tài khoản chứa Resource Group `Vy-Intern`):

```powershell
az vm run-command invoke --name azure-test-vm --resource-group Vy-Intern --command-id RunShellScript --scripts "ping -c 4 10.10.1.5 && ping -c 4 10.20.1.5" 
```

**Kết quả kỳ vọng:** Lệnh trả về file JSON với thuộc tính `"message": "Enable succeeded: [stdout] PING 10.10.1.5 ... 4 received ... PING 10.20.1.5 ... 4 received"`, xác nhận máy ảo Azure hoàn toàn có thể tìm thấy đường định tuyến (route) đi qua Tunnel-0 về phía mạng nội bộ của GCP.

---

### Troubleshooting Hybrid VPN

Nếu kết nối không thành công (Ping không thông), hãy kiểm tra theo thứ tự:

1. **Trạng thái BGP (GCP):**
   ```powershell
   gcloud compute routers get-status hub-cloud-router --region=asia-southeast1 --project=prj-hub-net-buiduchoang --format="table(result.bgpPeerStatus[].name,result.bgpPeerStatus[].status,result.bgpPeerStatus[].numLearnedRoutes)"
   ```
   *Yêu cầu: Status phải là `UP`.*

2. **Trạng thái Tunnel (GCP):**
   ```powershell
   gcloud compute vpn-tunnels list --project=prj-hub-net-buiduchoang --format="table(name,status,detailedStatus)"
   ```
   *Yêu cầu: Status phải là `ESTABLISHED`.*

3. **ASN & Shared Secret:**
   - GCP ASN: `65001`
   - Azure ASN: `65010`
   - Shared Secret: `AzureGCP123!` (Phải khớp 100% cả 2 bên).

4. **Lỗi SSH Key (Azure):**
   Nếu gặp lỗi `id_rsa.pub: no such file`, hãy tạo key trước khi apply:
   ```powershell
   ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa" -N '""'
   ```
