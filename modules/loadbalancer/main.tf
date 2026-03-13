# Reserve global static IP
resource "google_compute_global_address" "this" {
  name    = "${var.name}-ip"
  project = var.project_id
}

# Health Check
resource "google_compute_health_check" "this" {
  name    = "${var.name}-hc"
  project = var.project_id

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Backend Service
resource "google_compute_backend_service" "this" {
  name        = "${var.name}-backend"
  project     = var.project_id
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30
  enable_cdn  = var.enable_cdn

  dynamic "backend" {
    for_each = var.backends
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      max_utilization = backend.value.max_utilization
    }
  }

  health_checks = [google_compute_health_check.this.id]
}

# URL Map
resource "google_compute_url_map" "this" {
  name            = "${var.name}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.this.id
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "this" {
  count = length(var.ssl_certificates) == 0 ? 1 : 0

  name    = "${var.name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.this.id
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "this" {
  count = length(var.ssl_certificates) > 0 ? 1 : 0

  name             = "${var.name}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.this.id
  ssl_certificates = var.ssl_certificates
}

# HTTP Forwarding Rule
resource "google_compute_global_forwarding_rule" "http" {
  count = length(var.ssl_certificates) == 0 ? 1 : 0

  name       = "${var.name}-http-rule"
  project    = var.project_id
  target     = google_compute_target_http_proxy.this[0].id
  ip_address = google_compute_global_address.this.address
  port_range = "80"
}

# HTTPS Forwarding Rule
resource "google_compute_global_forwarding_rule" "https" {
  count = length(var.ssl_certificates) > 0 ? 1 : 0

  name       = "${var.name}-https-rule"
  project    = var.project_id
  target     = google_compute_target_https_proxy.this[0].id
  ip_address = google_compute_global_address.this.address
  port_range = "443"
}
