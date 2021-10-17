# Declaration of Cloud Provider
provider "aws" {
  region = "us-east-1"
}

# Backend Bucket
terraform {
  backend "s3" {
    region = "us-east-1"
  }
}

# Deploy Domain Hosted Zone in Route53
module "route53_alias" {
  source        = "../modules/route53_alias"
  zone_id       = var.zone_id
  domain_name   = var.domain_name
  record_type   = var.record_type
  alb_dns_name  = var.alb_dns_name
  alb_host_zone = var.alb_host_zone
}
