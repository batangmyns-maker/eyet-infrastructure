# 기본 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "bt-portal"
}

variable "environment" {
  description = "환경"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# 도메인 설정
variable "use_custom_domain" {
  description = "커스텀 도메인 사용 여부 (false면 CloudFront 기본 도메인 사용)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "기본 도메인 이름 (use_custom_domain이 true일 때 필요)"
  type        = string
  default     = ""
}

# VPC 설정
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.1.0.0/16"  # 운영 환경은 다른 CIDR 사용
}

variable "availability_zones" {
  description = "사용할 가용 영역"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "Public 서브넷 CIDR"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private 서브넷 CIDR"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

# EC2 설정
variable "ec2_instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"  # 운영 환경: 더 큰 인스턴스
}

variable "ec2_key_name" {
  description = "EC2 SSH Key Pair 이름 (Session Manager 사용 시 null)"
  type        = string
  default     = null
}

variable "ec2_ami_id" {
  description = "EC2 AMI ID (Amazon Linux 2023 kernel-6.1)"
  type        = string
  default     = "ami-04fcc2023d6e37430"  # Amazon Linux 2023 kernel-6.1 x86_64 (ap-northeast-2)
}

variable "allowed_ssh_cidrs" {
  description = "SSH 접근 허용 CIDR (Session Manager 사용 시 빈 배열)"
  type        = list(string)
  default     = []  # Session Manager 사용으로 SSH 비활성화
}

# RDS 설정
variable "rds_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.small"  # 비용 절감 (2GB RAM)
}

variable "rds_allocated_storage" {
  description = "RDS 스토리지 크기 (GB)"
  type        = number
  default     = 50  # 50GB로 축소 (필요 시 늘릴 수 있음)
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "btportal"
}

variable "db_username" {
  description = "데이터베이스 사용자 이름"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
  sensitive   = true
}

# 애플리케이션 설정
variable "server_port" {
  description = "애플리케이션 서버 포트"
  type        = number
  default     = 18082
}

variable "jwt_secret_key" {
  description = "JWT 시크릿 키"
  type        = string
  sensitive   = true
}

variable "toss_secret_key" {
  description = "토스페이먼츠 시크릿 키"
  type        = string
  sensitive   = true
}

variable "cors_allowed_origins" {
  description = "CORS 허용 오리진 (CloudFront 기본 도메인 사용 시 * 허용)"
  type        = list(string)
  default     = ["*"]  # 커스텀 도메인 사용 시 명시적으로 도메인 지정 필요
}


