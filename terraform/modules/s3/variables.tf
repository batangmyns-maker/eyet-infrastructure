variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

variable "cors_allowed_origins" {
  description = "CORS 허용 오리진 목록"
  type        = list(string)
  default     = ["*"]
}

# CloudFront ARN은 main.tf에서 S3 버킷 정책 생성 시 직접 사용
# (순환 의존성 해결을 위해 분리)


