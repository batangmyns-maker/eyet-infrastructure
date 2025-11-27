variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "bt-portal"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "cors_allowed_origins" {
  description = "로컬 버킷 테스트 시 허용할 CORS 오리진"
  type        = list(string)
  default     = ["http://localhost:3000", "http://127.0.0.1:3000"]
}

variable "trusted_operator_cidrs" {
  description = "로컬 환경에서 고정 IP(CIDR)"
  type        = list(string)
  default     = ["112.222.28.115/32"]
}


