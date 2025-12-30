output "db_credentials_secret_arn" {
  description = "RDS 자격증명 시크릿 ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "RDS 자격증명 시크릿 이름"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "jwt_secret_arn" {
  description = "JWT 시크릿 ARN"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "jwt_secret_name" {
  description = "JWT 시크릿 이름"
  value       = aws_secretsmanager_secret.jwt_secret.name
}

output "toss_secret_arn" {
  description = "Toss Payments 시크릿 ARN"
  value       = aws_secretsmanager_secret.toss_secret.arn
}

output "toss_secret_name" {
  description = "Toss Payments 시크릿 이름"
  value       = aws_secretsmanager_secret.toss_secret.name
}

output "cloudfront_private_key_secret_arn" {
  description = "CloudFront Private Key 시크릿 ARN"
  value       = aws_secretsmanager_secret.cloudfront_private_key.arn
}

output "cloudfront_private_key_secret_name" {
  description = "CloudFront Private Key 시크릿 이름"
  value       = aws_secretsmanager_secret.cloudfront_private_key.name
}

output "identity_verification_secret_arn" {
  description = "본인인증 시크릿 ARN"
  value       = try(aws_secretsmanager_secret.identity_verification[0].arn, null)
}

output "identity_verification_secret_name" {
  description = "본인인증 시크릿 이름"
  value       = try(aws_secretsmanager_secret.identity_verification[0].name, null)
}

output "identity_verification_encryption_key_secret_name" {
  description = "본인인증 암호화 키가 포함된 시크릿 이름"
  value       = try(aws_secretsmanager_secret.identity_verification[0].name, null)
}

output "google_oauth_secret_arn" {
  description = "Google OAuth 시크릿 ARN"
  value       = try(aws_secretsmanager_secret.google_oauth[0].arn, null)
}

output "google_oauth_secret_name" {
  description = "Google OAuth 시크릿 이름"
  value       = try(aws_secretsmanager_secret.google_oauth[0].name, null)
}

output "all_secret_arns" {
  description = "모든 시크릿 ARN 목록"
  value = concat(
    [
      aws_secretsmanager_secret.db_credentials.arn,
      aws_secretsmanager_secret.jwt_secret.arn,
      aws_secretsmanager_secret.toss_secret.arn,
      aws_secretsmanager_secret.cloudfront_private_key.arn
    ],
    var.openai_api_key != null ? [
      aws_secretsmanager_secret.openai[0].arn
    ] : [],
    var.identity_verification_key_file_password != null && var.identity_verification_client_prefix != null ? [
      aws_secretsmanager_secret.identity_verification[0].arn
    ] : [],
    var.google_oauth_client_secret != null ? [
      aws_secretsmanager_secret.google_oauth[0].arn
    ] : []
  )
}

