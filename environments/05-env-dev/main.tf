###############################################################################
# Dev VM
###############################################################################
module "dev_vm" {
  source = "../../modules/compute"

  project_id   = var.dev_project_id
  name         = "dev-vm"
  zone         = var.zone
  machine_type = var.vm_machine_type
  network      = var.network_self_link
  subnetwork   = var.subnet_self_link
  internal_ip  = "10.10.1.5"

  tags = ["http-server", "dev"]

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }

  install_ops_agent = true

  additional_startup_script = <<-EOT
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>Dev VM - $(hostname)</h1><p>Internal IP: 10.10.1.5</p>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOT
}

###############################################################################
# IAM — Allow Dev project to use Shared VPC subnet
###############################################################################
data "google_project" "dev" {
  project_id = var.dev_project_id
}

resource "google_compute_subnetwork_iam_member" "dev_subnet_user" {
  project    = var.hub_project_id
  region     = var.region
  subnetwork = "dev-subnet"
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.dev.number}@cloudservices.gserviceaccount.com"
}

###############################################################################
# HTTP Load Balancer (same project as instance group)
###############################################################################
module "dev_lb" {
  source = "../../modules/loadbalancer"

  project_id = var.dev_project_id
  name       = "dev-external-lb"

  backends = {
    dev-vm = {
      group = module.dev_vm.instance_group
    }
  }
}
