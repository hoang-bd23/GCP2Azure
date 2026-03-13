###############################################################################
# Prod VM
###############################################################################
module "prod_vm" {
  source = "../../modules/compute"

  project_id   = var.prod_project_id
  name         = "prod-vm"
  zone         = var.zone
  machine_type = var.vm_machine_type
  network      = var.network_self_link
  subnetwork   = var.subnet_self_link
  internal_ip  = "10.20.1.5"

  tags = ["http-server", "prod"]

  labels = {
    environment = "prod"
    managed_by  = "terraform"
  }

  install_ops_agent = true

  additional_startup_script = <<-EOT
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>Prod VM - $(hostname)</h1><p>Internal IP: 10.20.1.5</p>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOT
}

###############################################################################
# IAM — Allow Prod project to use Shared VPC subnet
###############################################################################
data "google_project" "prod" {
  project_id = var.prod_project_id
}

resource "google_compute_subnetwork_iam_member" "prod_subnet_user" {
  project    = var.hub_project_id
  region     = var.region
  subnetwork = "prod-subnet"
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.prod.number}@cloudservices.gserviceaccount.com"
}

###############################################################################
# HTTP Load Balancer (same project as instance group)
###############################################################################
module "prod_lb" {
  source = "../../modules/loadbalancer"

  project_id = var.prod_project_id
  name       = "prod-external-lb"

  backends = {
    prod-vm = {
      group = module.prod_vm.instance_group
    }
  }
}
