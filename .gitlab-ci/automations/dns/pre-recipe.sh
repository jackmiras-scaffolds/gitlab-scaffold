#!/bin/bash
# This shell script creates a DNS Alias Record in AWS Route53 to
# the application being deployed in our Kubernetes cluster

# Variables
ENV=$1
APP=$2
readonly DOMAIN="mydomain.com"

if [[ -z "${ENV}" ]]; then
  echo "Pass environment to the script!" && exit 1
fi

if [[ -z "${APP}" ]]; then
  echo "Pass your app name to the script!" && exit 1
fi

# Get the Application Load Balancer Domain Name
readonly ALB_DNS=$(kubectl -n "${ENV}" describe ingress "${ENV}"-ingress | grep -i Address: | awk '{ print $2 }')

# Get the Application Load Balancer Hosted Zone ID
readonly ALB_HOSTED_ZONE=$(aws elbv2 describe-load-balancers | grep CanonicalHostedZoneId | head -1 | cut -d '"' -f 4)

# Get the Hosted Zone ID of Route53 Domain in AWS
readonly HOSTED_ZONE_NAME=$(aws route53 list-hosted-zones | grep Name | awk '{ print $2 }' | cut -d '"' -f 2)

if [[ "${HOSTED_ZONE_NAME}" == "${DOMAIN}" || "${HOSTED_ZONE_NAME}" == "${ENV}.${DOMAIN}" ]]; then
  readonly HOSTED_ZONE_ID=$(aws route53 list-hosted-zones | grep Id | cut -d '/' -f 3 | cut -d '"' -f 1)
else
  echo "Hosted zones '${DOMAIN}' and '${ENV}.${DOMAIN}' doesn't exists" && exit 1
fi

# Set the variable for Domain Name in Case of Production and other Environments
if [[ $ENV = "production" ]]; then
  readonly APP_DOMAIN="$APP.${DOMAIN}"
else
  readonly APP_DOMAIN="$APP.$ENV.${DOMAIN}"
fi

# Set the variables in Terraform Vars
cat > vars.tf << EOF
variable "zone_id" {
  default = "$HOSTED_ZONE_ID"
}
variable "domain_name" {
  default = "$APP_DOMAIN"
}
variable "record_type" {
  default = "A"
}
variable "alb_dns_name" {
  default = "$ALB_DNS"
}
variable "alb_host_zone" {
  default = "$ALB_HOSTED_ZONE"
}
EOF
