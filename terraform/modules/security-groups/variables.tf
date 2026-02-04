variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "app_port" {
  description = "애플리케이션 포트"
  type        = number
  default     = 18082
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록 (Query Editor v2 접근용)"
  type        = string
}

variable "trusted_operator_cidrs" {
  description = "운영자 직접 접근을 허용할 CIDR 목록 (EC2, RDS 직접 접근용)"
  type        = list(string)
  default     = []
}
