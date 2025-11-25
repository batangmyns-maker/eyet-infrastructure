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

variable "allowed_ssh_cidrs" {
  description = "SSH 접근을 허용할 CIDR 블록 목록 (빈 배열이면 SSH 비활성화, Session Manager 사용)"
  type        = list(string)
  default     = []  # Session Manager 사용 시 빈 배열
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록 (Query Editor v2 접근용)"
  type        = string
}


