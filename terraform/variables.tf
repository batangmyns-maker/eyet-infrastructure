# ============================================================
# 공통 변수 정의 (모든 환경에서 사용)
# 실제 값은 각 환경의 terraform.tfvars에서 설정
# ============================================================

# 기본 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  # default 제거 - 각 환경에서 필수 입력
}

variable "environment" {
  description = "환경 (local, prod 등)"
  type        = string
  # default 제거 - 각 환경에서 필수 입력
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  # default 제거 - 각 환경에서 필수 입력
}

variable "aws_profile" {
  description = "로컬에서 사용할 AWS CLI profile 이름 (~/.aws/config). null이면 기본 credential chain 사용"
  type        = string
  default     = null
}

variable "terraform_role_arn" {
  description = "Terraform이 AssumeRole로 사용할 IAM Role ARN (회사 IP에서만 Assume 가능하도록 Trust Policy로 제한 권장)"
  type        = string
  default     = null
}

variable "terraform_sso_principal_arn" {
  description = "Terraform 실행을 허용할 SSO Principal(Role) ARN (예: AWSReservedSSO_* Role ARN). 설정 시 Terraform 전용 Role을 생성할 때 Trust Policy Principal로 사용"
  type        = string
  default     = null
}

variable "terraform_bootstrap_principal_arn" {
  description = "SSO 전환 전 부트스트랩 용도로 Terraform 전용 Role Assume을 허용할 IAM Principal ARN (예: arn:aws:iam::<account-id>:user/terraform-admin). terraform_sso_principal_arn 설정 후 제거 권장"
  type        = string
  default     = null
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
  # default 제거 - 각 환경에서 필수 입력
}

variable "availability_zones" {
  description = "사용할 가용 영역"
  type        = list(string)
  # default 제거 - 각 환경에서 필수 입력
}

variable "public_subnet_cidrs" {
  description = "Public 서브넷 CIDR"
  type        = list(string)
  # default 제거 - 각 환경에서 필수 입력
}

variable "private_subnet_cidrs" {
  description = "Private 서브넷 CIDR"
  type        = list(string)
  # default 제거 - 각 환경에서 필수 입력
}

variable "trusted_operator_cidrs" {
  description = "관리자가 접속하는 고정 IP(CIDR)"
  type        = list(string)
  default     = []
}

# EC2 설정
variable "ec2_instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = null  # prod 환경에서만 사용
}

variable "ec2_key_name" {
  description = "EC2 SSH Key Pair 이름 (Session Manager 사용 시 null)"
  type        = string
  default     = null
}

variable "ec2_ami_id" {
  description = "EC2 AMI ID (Amazon Linux 2023 kernel-6.1)"
  type        = string
  default     = null  # prod 환경에서만 사용
}

# RDS 설정
variable "rds_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = null  # prod 환경에서만 사용
}

variable "rds_allocated_storage" {
  description = "RDS 스토리지 크기 (GB)"
  type        = number
  default     = null  # prod 환경에서만 사용
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = null  # prod 환경에서만 사용
}

variable "db_username" {
  description = "데이터베이스 사용자 이름"
  type        = string
  default     = null  # prod 환경에서만 사용
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
  sensitive   = true
  default     = null  # prod 환경에서만 사용
}

variable "rds_publicly_accessible" {
  description = "RDS 퍼블릭 접근 허용 여부"
  type        = bool
  default     = false
}

# 애플리케이션 설정
variable "server_port" {
  description = "애플리케이션 서버 포트"
  type        = number
  default     = 18082
}

variable "cloudfront_backend_port" {
  description = "CloudFront 오리진이 연결할 포트 (Nginx 리버스 프록시 등)"
  type        = number
  default     = 80
}

variable "jwt_secret_key" {
  description = "JWT 시크릿 키"
  type        = string
  sensitive   = true
  default     = null  # prod 환경에서만 사용
}

variable "toss_secret_key" {
  description = "토스페이먼츠 시크릿 키"
  type        = string
  sensitive   = true
  default     = null  # prod 환경에서만 사용
}

variable "toss_security_key" {
  description = "토스페이먼츠 보안키"
  type        = string
  sensitive   = true
  default     = null  # prod 환경에서만 사용
}

variable "toss_billing_secret_key" {
  description = "토스페이먼츠 Billing 시크릿 키"
  type        = string
  sensitive   = true
  default     = null  # prod 환경에서만 사용
}

variable "toss_billing_security_key" {
  description = "토스페이먼츠 Billing 보안키"
  type        = string
  sensitive   = true
  default     = null  # prod 환경에서만 사용
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
  default     = null
}

variable "cors_allowed_origins" {
  description = "CORS 허용 오리진"
  type        = list(string)
  # default 제거 - 각 환경에서 필수 입력
}

# SES 설정
variable "ses_verified_email_addresses" {
  description = "SES에서 인증할 이메일 주소 목록 (다른 도메인의 이메일 주소 포함 가능)"
  type        = list(string)
  default     = []
}

variable "ses_additional_domains" {
  description = "추가로 인증할 도메인 목록 (여러 도메인 사용 시)"
  type        = list(string)
  default     = []
}

variable "ses_enable_dmarc" {
  description = "DMARC 레코드 활성화 여부"
  type        = bool
  default     = false
}

variable "ses_dmarc_email" {
  description = "DMARC 리포트를 받을 이메일 주소 (ses_enable_dmarc가 true일 때 필요)"
  type        = string
  default     = ""
}

variable "ses_dmarc_policy" {
  description = "DMARC 정책 레벨 (none: 모니터링만, quarantine: 스팸함으로 이동, reject: 완전 차단)"
  type        = string
  default     = "none"
}

# CloudFront Signed URL 설정
variable "cloudfront_key_group_id" {
  description = "CloudFront Key Group ID (Signed URL용) - AWS Console에서 Key Pair 생성 후 여기에 입력. 비공개 파일 다운로드에 필요"
  type        = string
  default     = null
}

variable "cloudfront_key_pair_id" {
  description = "CloudFront Public Key ID (Signed URL 생성에 사용) - AWS Console에서 Public Key 생성 시 할당된 ID"
  type        = string
  default     = null
}

variable "cloudfront_private_key" {
  description = "CloudFront Signed URL 생성용 Private Key (PEM 형식) - 로컬에서 생성한 private_key.pem 파일 내용. Secrets Manager에 저장됨"
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

