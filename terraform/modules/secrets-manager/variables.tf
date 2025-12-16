variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, prod)"
  type        = string
}

# 데이터베이스 자격증명
variable "db_host" {
  description = "데이터베이스 호스트"
  type        = string
}

variable "db_port" {
  description = "데이터베이스 포트"
  type        = number
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "데이터베이스 사용자 이름"
  type        = string
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
  sensitive   = true
}

# 애플리케이션 시크릿
variable "jwt_secret_key" {
  description = "JWT 시크릿 키"
  type        = string
  sensitive   = true
}

variable "toss_secret_key" {
  description = "Toss Payments 시크릿 키"
  type        = string
  sensitive   = true
}

variable "toss_security_key" {
  description = "Toss Payments 보안키"
  type        = string
  sensitive   = true
}

variable "cloudfront_private_key" {
  description = "CloudFront Signed URL 생성용 Private Key (PEM 형식) - 선택사항"
  type        = string
  sensitive   = true
  default     = ""  # Key Pair 생성 전까지는 빈 값
}

# 본인인증 설정
variable "identity_verification_key_file_password" {
  description = "본인인증 키파일 패스워드"
  type        = string
  sensitive   = true
  default     = null
}

variable "identity_verification_client_prefix" {
  description = "본인인증 회원사 ID (드림시큐리티에서 제공)"
  type        = string
  sensitive   = true
  default     = null
}

variable "identity_verification_encryption_key" {
  description = "본인인증정보 DB 저장 시 사용할 암호화/복호화 키 (AES-256: 32바이트, Base64 인코딩 권장)"
  type        = string
  sensitive   = true
  default     = null
}

# Google OAuth 설정
variable "google_oauth_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
  sensitive   = true
  default     = null
}

