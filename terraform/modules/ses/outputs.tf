output "domain_identity_arn" {
  description = "SES 도메인 인증 ARN"
  value       = var.domain_name != "" ? aws_ses_domain_identity.main[0].arn : ""
}

output "domain_identity_verification_token" {
  description = "도메인 인증 토큰 (Route53이 없을 때 수동 설정용)"
  value       = var.domain_name != "" ? aws_ses_domain_identity.main[0].verification_token : ""
}

output "dkim_tokens" {
  description = "DKIM 토큰 목록 (Route53이 없을 때 수동 설정용)"
  value       = var.domain_name != "" ? aws_ses_domain_dkim.main[0].dkim_tokens : []
}

output "verified_email_addresses" {
  description = "인증된 이메일 주소 목록"
  value       = { for email, identity in aws_ses_email_identity.main : email => identity.arn }
}

