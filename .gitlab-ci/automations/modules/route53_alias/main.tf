#Deploy a Alias Record in Route53 Domain
resource "aws_route53_record" "alias-record" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = var.record_type

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_host_zone
    evaluate_target_health = true
  }
}
