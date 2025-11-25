# 예시: 하나의 CloudFront Distribution으로 통합하는 방법
# 
# 이 파일은 예시입니다. 실제로 적용하려면 main.tf를 수정해야 합니다.

# 하나의 Distribution에 모든 Origin 추가
resource "aws_cloudfront_distribution" "unified" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} ${var.environment} Unified Distribution"
  price_class     = var.price_class

  # 여러 Origin 정의
  origin {
    domain_name              = var.frontend_bucket_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  origin {
    domain_name              = var.admin_bucket_domain_name
    origin_id                = "S3-Admin"
    origin_access_control_id = aws_cloudfront_origin_access_control.admin.id
  }

  origin {
    domain_name              = var.uploads_bucket_domain_name
    origin_id                = "S3-Uploads"
    origin_access_control_id = aws_cloudfront_origin_access_control.uploads.id
  }

  origin {
    domain_name = var.ec2_public_dns
    origin_id   = "EC2-Backend"

    custom_origin_config {
      http_port              = var.backend_port
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # 기본 동작 (프론트엔드)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"
    # ... 기타 설정
  }

  # 관리자 경로 분기
  ordered_cache_behavior {
    path_pattern     = "/admin/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Admin"
    # ... 기타 설정
  }

  # API 경로 분기
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "EC2-Backend"
    # 캐싱 비활성화 (API)
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    # ... 기타 설정
  }

  # 업로드 파일 경로 분기
  ordered_cache_behavior {
    path_pattern     = "/uploads/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Uploads"
    # 긴 캐시 시간
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
    # ... 기타 설정
  }

  # Lambda@Edge로 Host 헤더 기반 분기도 가능
  # 예: www.example.com → 프론트엔드, api.example.com → 백엔드
}
