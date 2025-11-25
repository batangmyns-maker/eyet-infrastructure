# VPC 출력
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# EC2 출력
output "ec2_instance_id" {
  description = "EC2 인스턴스 ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 Public IP"
  value       = module.ec2.elastic_ip
}

# RDS 출력
output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS 주소"
  value       = module.rds.db_instance_address
  sensitive   = true
}

# S3 출력
output "s3_frontend_bucket" {
  description = "프론트엔드 S3 버킷"
  value       = module.s3.frontend_bucket_id
}

output "s3_admin_bucket" {
  description = "관리자 S3 버킷"
  value       = module.s3.admin_bucket_id
}

output "s3_uploads_bucket" {
  description = "업로드 S3 버킷"
  value       = module.s3.uploads_bucket_id
}

# CloudFront 출력 (항상 출력 - 기본 도메인)
output "cloudfront_frontend_url" {
  description = "프론트엔드 CloudFront URL"
  value       = "https://${module.cloudfront.frontend_distribution_domain_name}"
}

output "cloudfront_admin_url" {
  description = "관리자 CloudFront URL"
  value       = "https://${module.cloudfront.admin_distribution_domain_name}"
}

output "cloudfront_api_url" {
  description = "API CloudFront URL"
  value       = "https://${module.cloudfront.api_distribution_domain_name}"
}

output "cloudfront_cdn_url" {
  description = "CDN CloudFront URL"
  value       = "https://${module.cloudfront.uploads_distribution_domain_name}"
}

# Route 53 출력 (커스텀 도메인 사용 시에만)
output "route53_name_servers" {
  description = "Route 53 네임서버 (가비아에 설정 필요)"
  value       = var.use_custom_domain ? aws_route53_zone.main[0].name_servers : []
}

# 커스텀 도메인 URL (사용 시에만)
output "custom_frontend_url" {
  description = "프론트엔드 커스텀 URL"
  value       = var.use_custom_domain ? "https://www.${var.domain_name}" : null
}

output "custom_admin_url" {
  description = "관리자 커스텀 URL"
  value       = var.use_custom_domain ? "https://admin.${var.domain_name}" : null
}

output "custom_api_url" {
  description = "API 커스텀 URL"
  value       = var.use_custom_domain ? "https://api.${var.domain_name}" : null
}

output "custom_cdn_url" {
  description = "CDN 커스텀 URL"
  value       = var.use_custom_domain ? "https://cdn.${var.domain_name}" : null
}

# ACM 출력 (커스텀 도메인 사용 시에만)
output "acm_certificate_arn" {
  description = "ACM 인증서 ARN"
  value       = var.use_custom_domain ? module.acm[0].certificate_arn : null
}

# 배포 정보
output "deployment_info" {
  description = "배포 정보 요약"
  value = {
    environment       = var.environment
    region            = var.aws_region
    use_custom_domain = var.use_custom_domain
    urls = {
      frontend = "https://${module.cloudfront.frontend_distribution_domain_name}"
      admin    = "https://${module.cloudfront.admin_distribution_domain_name}"
      api      = "https://${module.cloudfront.api_distribution_domain_name}"
      cdn      = "https://${module.cloudfront.uploads_distribution_domain_name}"
    }
  }
}
