resource "google_compute_security_policy" "waf_policy" {
  name        = "waf-policy"
  description = "Web Application Firewall Policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["10.8.0.0/28", "10.0.0.0/24", "10.0.1.0/28", var.load_balancer_ip] # # vpc, subnet, load balancer and gke master ipv4 cidr range 
      }
    }
    description = "Allow traffic from specific IP range"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny all other traffic"
  }
}
