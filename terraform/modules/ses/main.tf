# ============================================================
# AWS SES (Simple Email Service) 모듈
# 이메일 발송을 위한 도메인 인증 및 설정
# ============================================================

# SES 도메인 인증 (도메인이 있는 경우만)
resource "aws_ses_domain_identity" "main" {
  count  = var.domain_name != "" ? 1 : 0
  domain = var.domain_name

  depends_on = [var.route53_zone_id]
}

# DKIM 서명 활성화 (도메인이 있는 경우만)
resource "aws_ses_domain_dkim" "main" {
  count  = var.domain_name != "" ? 1 : 0
  domain = aws_ses_domain_identity.main[0].domain
}

# Route53에 DKIM 레코드 추가 (도메인과 Route53이 있는 경우)
resource "aws_route53_record" "dkim" {
  count   = var.domain_name != "" && var.route53_zone_id != "" ? 3 : 0
  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.main[0].dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# Route53에 도메인 인증 레코드 추가 (도메인과 Route53이 있는 경우)
resource "aws_route53_record" "domain_verification" {
  count   = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.main[0].domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main[0].verification_token]
}

# 도메인 인증 완료 대기 (도메인과 Route53이 있는 경우)
resource "aws_ses_domain_identity_verification" "main" {
  count  = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  domain = aws_ses_domain_identity.main[0].id

  timeouts {
    create = "5m"
  }

  depends_on = [aws_route53_record.domain_verification]
}

# SPF 레코드 (도메인과 Route53이 있는 경우)
resource "aws_route53_record" "spf" {
  count   = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DMARC 레코드 (선택사항, 도메인과 Route53이 있고 DMARC가 활성화된 경우)
resource "aws_route53_record" "dmarc" {
  count   = var.domain_name != "" && var.route53_zone_id != "" && var.enable_dmarc ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=${var.dmarc_policy}; rua=mailto:${var.dmarc_email}"]
}

# 이메일 주소 인증 (선택사항)
resource "aws_ses_email_identity" "main" {
  for_each = toset(var.verified_email_addresses)
  email    = each.value
}

# 프로덕션 환경에서 샌드박스 해제 요청 (수동 작업 필요)
# 참고: AWS 콘솔에서 수동으로 요청해야 합니다.
# https://console.aws.amazon.com/ses/home?region=ap-northeast-2#/account

