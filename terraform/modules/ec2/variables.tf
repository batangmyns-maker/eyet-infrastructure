variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2023 kernel-6.1 권장)"
  type        = string
  # Amazon Linux 2023 kernel-6.1 AMI (서울 리전)
  # 5년 장기 지원(LTS) 제공
  default = "ami-04fcc2023d6e37430"  # Amazon Linux 2023 kernel-6.1 x86_64 (ap-northeast-2)
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "SSH Key Pair 이름 (Session Manager 사용 시 null)"
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "Public 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "root_volume_size" {
  description = "Root 볼륨 크기 (GB)"
  type        = number
  default     = 30
}

variable "uploads_bucket_name" {
  description = "파일 업로드용 S3 버킷 이름"
  type        = string
}

variable "file_transfer_bucket_name" {
  description = "파일 이동용 S3 버킷 이름 (로컬 -> EC2)"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전 (provider region과 동일)"
  type        = string
}

# 데이터베이스 설정
variable "db_host" {
  description = "데이터베이스 호스트"
  type        = string
}

variable "db_port" {
  description = "데이터베이스 포트"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "데이터베이스 사용자 이름"
  type        = string
}

# 애플리케이션 설정
variable "server_port" {
  description = "애플리케이션 서버 포트"
  type        = number
  default     = 18082
}

variable "cors_allowed_origin" {
  description = "CORS 허용 오리진"
  type        = string
  default     = "*"
}

# Secrets Manager 설정
variable "secret_arns" {
  description = "Secrets Manager 시크릿 ARN 목록"
  type        = list(string)
}

variable "db_credentials_secret_name" {
  description = "RDS 자격증명 시크릿 이름"
  type        = string
}

variable "jwt_secret_name" {
  description = "JWT 시크릿 이름"
  type        = string
}

variable "toss_secret_name" {
  description = "Toss Payments 시크릿 이름"
  type        = string
}

variable "cloudfront_private_key_secret_name" {
  description = "CloudFront Private Key 시크릿 이름"
  type        = string
  default     = ""
}

variable "private_files_bucket_name" {
  description = "비공개 파일용 S3 버킷 이름"
  type        = string
}

variable "cloudfront_private_distribution_domain" {
  description = "비공개 CloudFront Distribution Domain Name"
  type        = string
  default     = ""
}

variable "cloudfront_key_pair_id" {
  description = "CloudFront Key Pair ID (Signed URL용)"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN (백엔드 로그용)"
  type        = string
}

variable "api_domain" {
  description = "API 도메인 (api.example.com) - nginx server_name에 사용"
  type        = string
  default     = ""
}
