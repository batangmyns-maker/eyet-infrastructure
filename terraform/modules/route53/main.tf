# Route 53 호스팅 영역 (가비아에서 이관한 도메인)
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-hosted-zone"
    Environment = var.environment
    Project     = var.project_name
  }
}

# A 레코드 - 프론트엔드 (www)
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.frontend_subdomain
  type    = "A"

  alias {
    name                   = var.frontend_cloudfront_domain
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA 레코드 - 프론트엔드 (IPv6)
resource "aws_route53_record" "frontend_ipv6" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.frontend_subdomain
  type    = "AAAA"

  alias {
    name                   = var.frontend_cloudfront_domain
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# A 레코드 - API
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.api_subdomain
  type    = "A"

  alias {
    name                   = var.api_cloudfront_domain
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA 레코드 - API (IPv6)
resource "aws_route53_record" "api_ipv6" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.api_subdomain
  type    = "AAAA"

  alias {
    name                   = var.api_cloudfront_domain
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# A 레코드 - CDN
resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.cdn_subdomain
  type    = "A"

  alias {
    name                   = var.cdn_cloudfront_domain
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA 레코드 - CDN (IPv6)
resource "aws_route53_record" "cdn_ipv6" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.cdn_subdomain
  type    = "AAAA"

  alias {
    name                   = var.cdn_cloudfront_domain
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# ACM 인증서 검증용 CNAME 레코드
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in var.acm_domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}


