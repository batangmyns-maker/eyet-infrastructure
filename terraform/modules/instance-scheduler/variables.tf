variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ec2_instance_id" {
  description = "EC2 인스턴스 ID"
  type        = string
}

variable "rds_instance_identifier" {
  description = "RDS 인스턴스 식별자"
  type        = string
}

variable "start_cron" {
  description = "EC2 시작 cron (EventBridge Scheduler 형식)"
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "stop_cron" {
  description = "EC2/RDS 중지 cron (EventBridge Scheduler 형식)"
  type        = string
  default     = "cron(0 19 ? * MON-FRI *)"
}

variable "rds_start_cron" {
  description = "RDS 시작 cron (EC2보다 5분 먼저 시작)"
  type        = string
  default     = "cron(55 7 ? * MON-FRI *)"
}

variable "timezone" {
  description = "스케줄 타임존"
  type        = string
  default     = "Asia/Seoul"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
}
