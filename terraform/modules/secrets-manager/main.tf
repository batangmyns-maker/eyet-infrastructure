# AWS Secrets Manager 모듈
# 민감한 정보를 안전하게 저장하고 관리
# 
# ⚠️ 키 네이밍 규칙: 네임스페이스 충돌 방지를 위해 모든 키에 prefix 사용
# - DB 관련: db-*
# - JWT 관련: jwt-*
# - Toss 관련: toss-*
# - Google 관련: google-oauth-*

# 1. RDS 데이터베이스 자격증명
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "/${var.project_name}/${var.environment}/db"
  description = "RDS 데이터베이스 자격증명 (자동 로테이션 지원)"

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-credentials"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    "db-username" = var.db_username
    "db-password" = var.db_password
    "db-host"     = var.db_host
    "db-port"     = var.db_port
    "db-name"     = var.db_name
    engine        = "postgres"
  })
}

# 2. JWT Secret Key
resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "/${var.project_name}/${var.environment}/jwt"
  description = "JWT 토큰 서명용 시크릿 키"

  tags = {
    Name        = "${var.project_name}-${var.environment}-jwt-secret"
    Environment = var.environment
    Project     = var.project_name
  }
}

# JWT Secret - 평탄화된 구조
resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    "jwt-secret-key" = var.jwt_secret_key
  })
}

# 3. Toss Payments Secret Key
resource "aws_secretsmanager_secret" "toss_secret" {
  name        = "/${var.project_name}/${var.environment}/toss"
  description = "Toss Payments API 시크릿 키"

  tags = {
    Name        = "${var.project_name}-${var.environment}-toss-secret"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "toss_secret" {
  secret_id = aws_secretsmanager_secret.toss_secret.id
  secret_string = jsonencode({
    "toss-secret-key" = var.toss_secret_key
    "toss-security-key" = var.toss_security_key
    "toss-billing-secret-key" = var.toss_billing_secret_key
    "toss-billing-security-key" = var.toss_billing_security_key
  })
}

# OpenAI API Key
resource "aws_secretsmanager_secret" "openai" {
  count       = var.openai_api_key != null ? 1 : 0
  name        = "/${var.project_name}/${var.environment}/openai"
  description = "OpenAI API Key"

  tags = {
    Name        = "${var.project_name}-${var.environment}-openai"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "openai" {
  count     = var.openai_api_key != null ? 1 : 0
  secret_id = aws_secretsmanager_secret.openai[0].id
  secret_string = jsonencode({
    "openai-api-key" = var.openai_api_key
  })
}

# 4. CloudFront Private Key (Signed URL 생성용)
resource "aws_secretsmanager_secret" "cloudfront_private_key" {
  name        = "/${var.project_name}/${var.environment}/cloudfront-private-key"
  description = "CloudFront Signed URL 생성용 Private Key (PEM 형식)"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront-private-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "cloudfront_private_key" {
  secret_id = aws_secretsmanager_secret.cloudfront_private_key.id
  secret_string = jsonencode({
    "cloudfront-private-key" = var.cloudfront_private_key
  })
}

# 5. 본인인증 설정 (Identity Verification)
resource "aws_secretsmanager_secret" "identity_verification" {
  count       = var.identity_verification_key_file_password != null && var.identity_verification_client_prefix != null ? 1 : 0
  name        = "/${var.project_name}/${var.environment}/identity-verification"
  description = "본인인증 설정 (키파일 패스워드, 회원사 ID, DB 암호화 키)"

  tags = {
    Name        = "${var.project_name}-${var.environment}-identity-verification"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "identity_verification" {
  count     = var.identity_verification_key_file_password != null && var.identity_verification_client_prefix != null ? 1 : 0
  secret_id = aws_secretsmanager_secret.identity_verification[0].id
  secret_string = jsonencode({
    "key-file-password" = var.identity_verification_key_file_password
    "client-prefix"     = var.identity_verification_client_prefix
    "encryption-key"    = var.identity_verification_encryption_key != null ? var.identity_verification_encryption_key : ""
    "matching-key"      = var.identity_verification_matching_key != null ? var.identity_verification_matching_key : ""
  })
}

# 6. Google OAuth Client Secret
resource "aws_secretsmanager_secret" "google_oauth" {
  count       = var.google_oauth_client_secret != null ? 1 : 0
  name        = "/${var.project_name}/${var.environment}/google-oauth"
  description = "Google OAuth Client Secret"

  tags = {
    Name        = "${var.project_name}-${var.environment}-google-oauth"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "google_oauth" {
  count     = var.google_oauth_client_secret != null ? 1 : 0
  secret_id = aws_secretsmanager_secret.google_oauth[0].id
  secret_string = jsonencode({
    "google-oauth-client-secret" = var.google_oauth_client_secret
  })
}

# 선택사항: RDS 비밀번호 자동 로테이션 설정
# 참고: 로테이션 Lambda 함수가 필요하며, 추가 설정이 필요합니다.
# 운영 환경에서는 아래 주석을 해제하여 30일마다 자동 로테이션 활성화를 권장합니다.

# resource "aws_secretsmanager_secret_rotation" "db_credentials" {
#   secret_id           = aws_secretsmanager_secret.db_credentials.id
#   rotation_lambda_arn = aws_lambda_function.rotate_db_password.arn
#
#   rotation_rules {
#     automatically_after_days = 30
#   }
#
#   depends_on = [aws_lambda_function.rotate_db_password]
# }

