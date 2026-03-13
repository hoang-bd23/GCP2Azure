locals {
  ops_agent_script = var.install_ops_agent ? "#!/bin/bash\ncurl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh\nsudo bash add-google-cloud-ops-agent-repo.sh --also-install" : ""

  startup_script = join("\n", compact([
    local.ops_agent_script,
    var.additional_startup_script
  ]))
}

resource "google_compute_instance" "this" {
  name         = var.name
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type
  tags         = var.tags
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    network_ip = var.internal_ip

    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {}
    }
  }

  # Normalize CRLF to LF so startup scripts authored on Windows run correctly on Linux.
  metadata_startup_script = length(local.startup_script) > 0 ? replace(local.startup_script, "\r\n", "\n") : null

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true
}

# Unmanaged instance group for LB backend
resource "google_compute_instance_group" "this" {
  name    = "${var.name}-ig"
  project = var.project_id
  zone    = var.zone

  instances = [google_compute_instance.this.self_link]

  named_port {
    name = "http"
    port = 80
  }
}
