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

output "all_secret_arns" {
  description = "모든 시크릿 ARN 목록"
  value = [
    aws_secretsmanager_secret.db_credentials.arn,
    aws_secretsmanager_secret.jwt_secret.arn,
    aws_secretsmanager_secret.toss_secret.arn,
    aws_secretsmanager_secret.cloudfront_private_key.arn
  ]
}

