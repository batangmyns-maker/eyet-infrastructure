variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

variable "domain_name" {
  description = "기본 도메인 이름 (example.com)"
  type        = string
}

variable "frontend_subdomain" {
  description = "프론트엔드 서브도메인 (www.example.com)"
  type        = string
}

variable "api_subdomain" {
  description = "API 서브도메인 (api.example.com)"
  type        = string
}

variable "cdn_subdomain" {
  description = "CDN 서브도메인 (cdn.example.com)"
  type        = string
}

variable "frontend_cloudfront_domain" {
  description = "프론트엔드 CloudFront Domain Name"
  type        = string
}

variable "api_cloudfront_domain" {
  description = "API CloudFront Domain Name"
  type        = string
}

variable "cdn_cloudfront_domain" {
  description = "CDN CloudFront Domain Name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront Hosted Zone ID (고정값)"
  type        = string
  default     = "Z2FDTNDATAQYW2"  # CloudFront 전역 호스팅 영역 ID
}

variable "acm_domain_validation_options" {
  description = "ACM 인증서 검증 옵션"
  type = set(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
  default = []
}


