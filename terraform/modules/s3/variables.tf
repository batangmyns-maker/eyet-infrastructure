variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (local, dev, prod 등)"
  type        = string
}

variable "cors_allowed_origins" {
  description = "CORS 허용 오리진 목록"
  type        = list(string)
}

variable "trusted_operator_cidrs" {
  description = "신뢰할 수 있는 운영자 IP CIDR 목록"
  type        = list(string)
  default     = []
}

variable "cloudfront_frontend_distribution_arn" {
  description = "CloudFront Frontend Distribution ARN (Prod 환경에서만 사용)"
  type        = string
  default     = ""
}

variable "cloudfront_uploads_distribution_arn" {
  description = "CloudFront Uploads Distribution ARN (Prod 환경에서만 사용)"
  type        = string
  default     = ""
}

variable "ec2_role_arn" {
  description = "EC2 인스턴스 IAM Role ARN (Prod 환경에서만 사용)"
  type        = string
  default     = ""
}
