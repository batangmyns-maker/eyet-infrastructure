# AWS Secrets Manager 모듈
# 민감한 정보를 안전하게 저장하고 관리
# 
# ⚠️ 키 네이밍 규칙: 네임스페이스 충돌 방지를 위해 모든 키에 prefix 사용
# - DB 관련: db-*
# - JWT 관련: jwt-*
# - Toss 관련: toss-*

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

