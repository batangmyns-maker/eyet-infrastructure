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

variable "uploads_bucket_domain_name" {
  description = "업로드 S3 버킷 도메인 (공개 파일용)"
  type        = string
}

variable "private_files_bucket_domain_name" {
  description = "비공개 파일 S3 버킷 도메인 (결제 후 다운로드용)"
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

variable "root_domain" {
  description = "루트 도메인 (example.com)"
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

variable "api_allowed_origins" {
  description = "API CloudFront에서 허용할 Origin 목록 (CORS)"
  type        = list(string)
  default     = ["*"]
}

variable "private_cdn_domain" {
  description = "비공개 CDN 도메인 (private-cdn.example.com) - Signed URL이 필요한 파일용"
  type        = string
  default     = ""
}

variable "cloudfront_key_group_id" {
  description = "CloudFront Key Group ID (Signed URL용) - AWS Console에서 Key Pair 생성 후 여기에 입력"
  type        = string
  default     = null
}
