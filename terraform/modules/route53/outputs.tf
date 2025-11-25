output "hosted_zone_id" {
  description = "Route 53 호스팅 영역 ID"
  value       = aws_route53_zone.main.zone_id
}

output "hosted_zone_name_servers" {
  description = "Route 53 네임서버 목록 (가비아에 설정 필요)"
  value       = aws_route53_zone.main.name_servers
}

output "frontend_fqdn" {
  description = "프론트엔드 FQDN"
  value       = aws_route53_record.frontend.fqdn
}

output "admin_fqdn" {
  description = "관리자 FQDN"
  value       = aws_route53_record.admin.fqdn
}

output "api_fqdn" {
  description = "API FQDN"
  value       = aws_route53_record.api.fqdn
}

output "cdn_fqdn" {
  description = "CDN FQDN"
  value       = aws_route53_record.cdn.fqdn
}

output "acm_validation_record_fqdns" {
  description = "ACM 인증서 검증 레코드 FQDN 목록"
  value       = [for record in aws_route53_record.acm_validation : record.fqdn]
}


