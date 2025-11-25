variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

variable "domain_name" {
  description = "기본 도메인 이름"
  type        = string
}

variable "subject_alternative_names" {
  description = "추가 도메인 이름 목록 (SAN)"
  type        = list(string)
  default     = []
}

# validation_record_fqdns는 main.tf에서 ACM validation 시 직접 사용
# (순환 의존성 해결을 위해 분리)


