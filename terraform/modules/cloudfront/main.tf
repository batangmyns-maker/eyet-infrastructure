terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# CloudFront Function 코드 생성
locals {
  # IP 화이트리스트 체크 코드 (문자열로 정의)
  ip_whitelist_check_code = var.enable_ip_whitelist ? join("\n", [
    "  if (whitelist.length > 0 && clientIP) {",
    "    var ipAllowed = false;",
    "    for (var i = 0; i < whitelist.length; i++) {",
    "      var cidr = whitelist[i];",
    "      if (!cidr) continue;",
    "      if (cidr.indexOf('/') === -1) {",
    "        // 단일 IP 주소 비교",
    "        if (clientIP === cidr) {",
    "          ipAllowed = true;",
    "          break;",
    "        }",
    "      } else {",
    "        // CIDR 범위 체크",
    "        var cidrParts = cidr.split('/');",
    "        if (cidrParts.length === 2) {",
    "          var cidrIP = cidrParts[0];",
    "          var mask = parseInt(cidrParts[1]);",
    "          if (cidrIP && !isNaN(mask) && isIPInCIDR(clientIP, cidrIP, mask)) {",
    "            ipAllowed = true;",
    "            break;",
    "          }",
    "        }",
    "      }",
    "    }",
    "    if (!ipAllowed) {",
    "      // 화이트리스트에 없는 IP는 에러 페이지로 리다이렉트",
    "      request.uri = '${var.ip_whitelist_error_page}';",
    "      request.querystring = '';",
    "      return request;",
    "    }",
    "  }"
  ]) : ""

  # www 리다이렉트 코드 (문자열로 정의)
  redirect_code = var.use_custom_domain && var.root_domain != "" ? join("\n", [
    "  if (host === '${var.root_domain}') {",
    "    var uri = request.uri || '/';",
    "    var qs = request.querystring;",
    "    var querystring = '';",
    "    ",
    "    // 쿼리 스트링 재구성",
    "    if (qs) {",
    "      var qsParts = [];",
    "      for (var key in qs) {",
    "        if (qs.hasOwnProperty(key)) {",
    "          var value = qs[key].value || '';",
    "          qsParts.push(key + '=' + encodeURIComponent(value));",
    "        }",
    "      }",
    "      querystring = qsParts.join('&');",
    "    }",
    "    ",
    "    var redirectUrl = 'https://${var.frontend_domain}' + uri;",
    "    if (querystring) {",
    "      redirectUrl += '?' + querystring;",
    "    }",
    "    ",
    "    return {",
    "      statusCode: 301,",
    "      statusDescription: 'Moved Permanently',",
    "      headers: {",
    "        'location': { value: redirectUrl }",
    "      }",
    "    };",
    "  }"
  ]) : ""

  # CloudFront Function 전체 코드
  cloudfront_function_code = (var.use_custom_domain && var.root_domain != "") || var.enable_ip_whitelist ? join("\n", [
    "function handler(event) {",
    "  var request = event.request;",
    "  if (!request) return { statusCode: 500, statusDescription: 'Internal Server Error' };",
    "  var host = request.headers && request.headers.host ? request.headers.host.value : '';",
    "  // CloudFront Function에서는 event.viewer.ip를 사용해야 함",
    "  var clientIP = event.viewer && event.viewer.ip ? event.viewer.ip : '';",
    "  // X-Forwarded-For 헤더가 있으면 우선 사용 (실제 클라이언트 IP)",
    "  if (request.headers && request.headers['x-forwarded-for'] && request.headers['x-forwarded-for'].value) {",
    "    var forwardedIPs = request.headers['x-forwarded-for'].value.split(',');",
    "    if (forwardedIPs.length > 0) {",
    "      clientIP = forwardedIPs[0].trim();",
    "    }",
    "  }",
    "  ",
    "  // IP 화이트리스트 체크 (활성화된 경우)",
    "  var whitelist = [${length(var.trusted_operator_cidrs) > 0 ? join(",", [for ip in var.trusted_operator_cidrs : "'${replace(ip, "'", "\\'")}'"]) : ""}];",
    "  ",
    local.ip_whitelist_check_code,
    "  ",
    "  // 루트 도메인을 www로 리다이렉트",
    local.redirect_code,
    "  ",
    "  return request;",
    "}",
    "",
    "// IP를 숫자로 변환하는 함수",
    "function ipToNumber(ip) {",
    "  if (!ip || typeof ip !== 'string') return 0;",
    "  var ipParts = ip.split('.');",
    "  if (ipParts.length !== 4) return 0;",
    "  return (parseInt(ipParts[0]) << 24) +",
    "         (parseInt(ipParts[1]) << 16) +",
    "         (parseInt(ipParts[2]) << 8) +",
    "         parseInt(ipParts[3]);",
    "}",
    "",
    "// IP가 CIDR 범위에 있는지 확인하는 함수",
    "function isIPInCIDR(ip, cidrIP, mask) {",
    "  if (!ip || !cidrIP || !mask || mask < 0 || mask > 32) return false;",
    "  var ipNum = ipToNumber(ip);",
    "  var cidrNum = ipToNumber(cidrIP);",
    "  if (ipNum === 0 || cidrNum === 0) return false;",
    "  var maskNum = ~((1 << (32 - mask)) - 1);",
    "  return (ipNum & maskNum) === (cidrNum & maskNum);",
    "}"
  ]) : ""
}

# Lambda@Edge 관련 리소스는 옵션 2(CloudFront Function만 사용)로 인해 비활성화됨
# 필요시 아래 리소스들의 count를 활성화하여 다시 사용 가능
# 
# Lambda@Edge는 handler가 "index.handler"이므로 zip 파일 안에 "index.js"가 있어야 함
# 임시 디렉토리를 만들어서 index.js로 저장
# resource "local_file" "lambda_edge_index" {
#   count    = var.enable_ip_whitelist || (var.use_custom_domain && var.root_domain != "") ? 1 : 0
#   filename = "${path.module}/lambda-temp/index.js"
#   content  = local.lambda_edge_code
# }
# 
# data "archive_file" "lambda_edge_zip" {
#   count       = var.enable_ip_whitelist ? 1 : 0
#   type        = "zip"
#   source_dir  = "${path.module}/lambda-temp"
#   output_path = "${path.module}/lambda-edge-ip-whitelist.zip"
#   depends_on  = [local_file.lambda_edge_index]
# }
# 
# resource "aws_iam_role" "lambda_edge" {
#   count    = var.enable_ip_whitelist ? 1 : 0
#   name     = "${var.project_name}-${var.environment}-lambda-edge-role"
#   provider = aws.us_east_1
# 
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = [
#             "edgelambda.amazonaws.com",
#             "lambda.amazonaws.com"
#           ]
#         }
#       }
#     ]
#   })
# 
#   tags = {
#     Name        = "${var.project_name}-${var.environment}-lambda-edge-role"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }
# 
# resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
#   count      = var.enable_ip_whitelist ? 1 : 0
#   role       = aws_iam_role.lambda_edge[0].name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#   provider   = aws.us_east_1
# }
# 
# resource "aws_lambda_function" "ip_whitelist" {
#   count         = var.enable_ip_whitelist ? 1 : 0
#   filename      = data.archive_file.lambda_edge_zip[0].output_path
#   function_name = "${var.project_name}-${var.environment}-ip-whitelist"
#   role          = aws_iam_role.lambda_edge[0].arn
#   handler       = "index.handler"
#   runtime       = "nodejs18.x"
#   provider      = aws.us_east_1
#   publish       = true # Lambda@Edge는 버전이 필요하므로 publish = true 필수
# 
#   source_code_hash = data.archive_file.lambda_edge_zip[0].output_base64sha256
# 
#   # Lambda@Edge는 환경 변수를 지원하지 않으므로 제거
# 
#   tags = {
#     Name        = "${var.project_name}-${var.environment}-ip-whitelist"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# CloudFront Function - www 리다이렉트 + IP 화이트리스트 체크
resource "aws_cloudfront_function" "www_redirect" {
  count    = (var.use_custom_domain && var.root_domain != "") || var.enable_ip_whitelist ? 1 : 0
  name     = "${var.project_name}-${var.environment}-www-redirect"
  runtime  = "cloudfront-js-1.0"
  comment  = "Redirect ${var.root_domain} to ${var.frontend_domain} and IP whitelist check"
  publish  = true
  code     = local.cloudfront_function_code
}

# API 전용 CORS 헤더 정책
resource "aws_cloudfront_response_headers_policy" "api_cors" {
  name    = "${var.project_name}-${var.environment}-api-cors"
  comment = "CORS headers for API distribution"

  cors_config {
    access_control_allow_credentials = true

    access_control_allow_headers {
      items = ["Authorization", "Content-Type", "Accept", "Origin", "X-Requested-With"]
    }

    access_control_allow_methods {
      items = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    }

    access_control_allow_origins {
      items = var.api_allowed_origins
    }

    access_control_expose_headers {
      items = ["Content-Length", "Content-Type"]
    }

    origin_override = true
  }
}

# Origin Access Control - 프론트엔드
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-${var.environment}-frontend-oac"
  description                       = "OAC for Frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Origin Access Control - 업로드
resource "aws_cloudfront_origin_access_control" "uploads" {
  name                              = "${var.project_name}-${var.environment}-uploads-oac"
  description                       = "OAC for Uploads S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Origin Access Control - 비공개 파일
resource "aws_cloudfront_origin_access_control" "private_files" {
  name                              = "${var.project_name}-${var.environment}-private-files-oac"
  description                       = "OAC for Private Files S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution - 프론트엔드 (사용자)
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} Frontend"
  default_root_object = "index.html"
  price_class         = var.price_class

  # 커스텀 도메인 (선택사항)
  aliases = var.use_custom_domain ? compact([var.frontend_domain, var.root_domain]) : []

  origin {
    domain_name              = var.frontend_bucket_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"

    # CloudFront Function 연결 (www 리다이렉트 + IP 화이트리스트 체크)
    dynamic "function_association" {
      for_each = (var.use_custom_domain && var.root_domain != "") || var.enable_ip_whitelist ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.www_redirect[0].arn
      }
    }

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # SPA용 - 404를 index.html로 리다이렉트
  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 300
    response_code         = 200
    response_page_path    = "/index.html"
  }

  # SPA용 - 403도 index.html로 리다이렉트 (존재하지 않는 파일 접근 시 발생 가능)
  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 300
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 커스텀 도메인 사용 시 ACM 인증서, 아니면 CloudFront 기본 인증서
  viewer_certificate {
    acm_certificate_arn            = var.use_custom_domain ? var.acm_certificate_arn : null
    ssl_support_method             = var.use_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.use_custom_domain ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.use_custom_domain ? false : true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-cdn"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudFront Distribution - 백엔드 API
resource "aws_cloudfront_distribution" "api" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} ${var.environment} API"
  price_class     = var.price_class

  # 커스텀 도메인 (선택사항)
  aliases = var.use_custom_domain ? [var.api_domain] : []

  origin {
    domain_name = var.ec2_public_dns
    origin_id   = "EC2-Backend"

    custom_origin_config {
      http_port              = var.backend_port
      https_port             = 443
      origin_protocol_policy = "http-only" # EC2에서는 HTTP, CloudFront에서 HTTPS 처리
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-Header"
      value = var.custom_header_value
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "EC2-Backend"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.api_cors.id

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Origin", "Accept", "Content-Type"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.use_custom_domain ? var.acm_certificate_arn : null
    ssl_support_method             = var.use_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.use_custom_domain ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.use_custom_domain ? false : true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-cdn"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudFront Distribution - 파일/이미지 (공개용)
resource "aws_cloudfront_distribution" "uploads" {
  enabled         = true
  is_ipv6_enabled  = true
  comment          = "${var.project_name} ${var.environment} CDN (Public)"
  price_class      = var.price_class

  # 커스텀 도메인 (선택사항)
  aliases = var.use_custom_domain ? [var.cdn_domain] : []

  origin {
    domain_name              = var.uploads_bucket_domain_name
    origin_id                = "S3-Uploads"
    origin_access_control_id = aws_cloudfront_origin_access_control.uploads.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Uploads"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1일
    max_ttl                = 31536000 # 1년
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.use_custom_domain ? var.acm_certificate_arn : null
    ssl_support_method             = var.use_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.use_custom_domain ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.use_custom_domain ? false : true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cdn-public"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Public CDN"
  }
}

# CloudFront Distribution - 비공개 파일 (결제 후 다운로드용)
resource "aws_cloudfront_distribution" "private_uploads" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name} ${var.environment} Private CDN (Signed URL Required)"
  price_class     = var.price_class

  # 커스텀 도메인 (선택사항)
  aliases = var.use_custom_domain && var.private_cdn_domain != "" ? [var.private_cdn_domain] : []

  origin {
    domain_name              = var.private_files_bucket_domain_name
    origin_id                = "S3-Private-Files"
    origin_access_control_id = aws_cloudfront_origin_access_control.private_files.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Private-Files"

    # Signed URL을 위한 Trusted Key Groups 설정
    # 주의: CloudFront Key Pair는 AWS Console에서 수동으로 생성 후 key_group_id를 변수로 전달해야 함
    trusted_key_groups = var.cloudfront_key_group_id != null ? [var.cloudfront_key_group_id] : []

    forwarded_values {
      query_string = true  # Signed URL의 쿼리 파라미터를 전달하기 위해 true
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0  # 인증된 콘텐츠는 캐싱 최소화
    max_ttl                = 0
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.use_custom_domain ? var.acm_certificate_arn : null
    ssl_support_method             = var.use_custom_domain ? "sni-only" : null
    minimum_protocol_version       = var.use_custom_domain ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.use_custom_domain ? false : true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cdn-private"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Private CDN - Signed URL Required"
  }
}
