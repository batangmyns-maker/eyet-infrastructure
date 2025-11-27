variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_id" {
  description = "RDS Security Group ID"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL 엔진 버전"
  type        = string
  default     = "16.6"
}

variable "instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "할당된 스토리지 크기 (GB)"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "btportal"
}

variable "master_username" {
  description = "마스터 사용자 이름"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "마스터 사용자 비밀번호"
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
  description = "백업 보존 기간 (일)"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Multi-AZ 배포 여부"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "삭제 방지 활성화 여부"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "최종 스냅샷 생성 건너뛰기"
  type        = bool
  default     = false
}

variable "monitoring_role_arn" {
  description = "Enhanced Monitoring을 위한 IAM Role ARN (선택사항)"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Performance Insights 활성화 여부"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "RDS 퍼블릭 접근 허용 여부"
  type        = bool
  default     = false
}


