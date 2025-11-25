output "certificate_arn" {
  description = "ACM 인증서 ARN"
  value       = aws_acm_certificate.main.arn
}

output "certificate_domain_validation_options" {
  description = "도메인 검증 옵션"
  value       = aws_acm_certificate.main.domain_validation_options
}

output "certificate_status" {
  description = "인증서 상태"
  value       = aws_acm_certificate.main.status
}


