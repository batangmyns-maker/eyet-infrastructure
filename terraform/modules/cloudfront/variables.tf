variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

variable "use_custom_domain" {
  description = "커스텀 도메인 사용 여부 (false면 CloudFront 기본 도메인 사용)"
  type        = bool
  default     = false
}

variable "frontend_bucket_domain_name" {
  description = "프론트엔드 S3 버킷 도메인"
  type        = string
}

variable "admin_bucket_domain_name" {
  description = "관리자 S3 버킷 도메인"
  type        = string
}

variable "uploads_bucket_domain_name" {
  description = "업로드 S3 버킷 도메인"
  type        = string
}

variable "ec2_public_dns" {
  description = "EC2 Public DNS 이름 (CloudFront origin용)"
  type        = string
}

variable "backend_port" {
  description = "백엔드 애플리케이션 포트"
  type        = number
  default     = 18082
}

variable "frontend_domain" {
  description = "프론트엔드 도메인 (www.example.com)"
  type        = string
  default     = ""
}

variable "admin_domain" {
  description = "관리자 도메인 (admin.example.com)"
  type        = string
  default     = ""
}

variable "api_domain" {
  description = "API 도메인 (api.example.com)"
  type        = string
  default     = ""
}

variable "cdn_domain" {
  description = "CDN 도메인 (cdn.example.com)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM SSL 인증서 ARN (us-east-1 리전)"
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront Price Class"
  type        = string
  default     = "PriceClass_200" # 미국, 유럽, 아시아, 중동, 아프리카
}

variable "custom_header_value" {
  description = "CloudFront에서 EC2로 전송할 커스텀 헤더 값 (보안용)"
  type        = string
  default     = "random-secret-value-12345"
}
