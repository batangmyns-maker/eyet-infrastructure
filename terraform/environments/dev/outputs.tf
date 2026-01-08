output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "ec2_public_ip" {
  value = module.ec2.elastic_ip
}

output "rds_endpoint" {
  value     = module.rds.db_instance_endpoint
  sensitive = true
}

output "cloudfront_frontend_url" {
  value = "https://${module.cloudfront.frontend_distribution_domain_name}"
}

output "cloudfront_api_url" {
  value = "https://${module.cloudfront.api_distribution_domain_name}"
}

output "custom_frontend_url" {
  value = "https://dev.www.${var.domain_name}"
}

output "custom_api_url" {
  value = "https://dev.api.${var.domain_name}"
}

output "custom_cdn_url" {
  value = "https://dev.cdn.${var.domain_name}"
}

output "custom_private_cdn_url" {
  value = "https://dev.private-cdn.${var.domain_name}"
}
