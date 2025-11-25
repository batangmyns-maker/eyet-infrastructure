terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bt-portal-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "bt-portal-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================
# 1단계: 기본 인프라 (VPC, Security Groups)
# ============================================================

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_groups" {
  source = "../../modules/security-groups"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  app_port          = var.server_port
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

# ============================================================
# 2단계: 데이터베이스 및 시크릿
# ============================================================

module "rds" {
  source = "../../modules/rds"

  project_name                 = var.project_name
  environment                  = var.environment
  private_subnet_ids           = module.vpc.private_subnet_ids
  security_group_id            = module.security_groups.rds_security_group_id
  instance_class               = var.rds_instance_class
  allocated_storage            = var.rds_allocated_storage
  database_name                = var.db_name
  master_username              = var.db_username
  master_password              = var.db_password
  backup_retention_period      = 7                 # 비용 절감: 7일
  multi_az                     = false             # 비용 절감: Single-AZ
  deletion_protection          = true              # 운영 환경: 삭제 방지 활성화
  skip_final_snapshot          = false             # 운영 환경: 최종 스냅샷 생성
  performance_insights_enabled = true              # 운영 환경: Performance Insights 활성화
  monitoring_role_arn          = null              # Enhanced Monitoring 비활성화 (IAM Role 별도 생성 필요)
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project_name    = var.project_name
  environment     = var.environment
  db_host         = module.rds.db_instance_address
  db_port         = module.rds.db_instance_port
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password
  jwt_secret_key  = var.jwt_secret_key
  toss_secret_key = var.toss_secret_key

  depends_on = [module.rds]
}

# ============================================================
# 3단계: S3 버킷
# ============================================================

module "s3" {
  source = "../../modules/s3"

  project_name         = var.project_name
  environment          = var.environment
  cors_allowed_origins = var.cors_allowed_origins
}

# ============================================================
# 4단계: ACM 인증서 (커스텀 도메인 사용 시에만)
# ============================================================

module "acm" {
  count  = var.use_custom_domain ? 1 : 0
  source = "../../modules/acm"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment
  domain_name  = "*.${var.domain_name}"

  subject_alternative_names = [
    var.domain_name,
    "*.${var.domain_name}"
  ]
}

# ============================================================
# 5단계: Route53 (커스텀 도메인 사용 시에만)
# ============================================================

# Route53 호스팅 영역
resource "aws_route53_zone" "main" {
  count = var.use_custom_domain ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-hosted-zone"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ACM 인증서 검증용 CNAME 레코드
resource "aws_route53_record" "acm_validation" {
  for_each = var.use_custom_domain ? {
    for dvo in module.acm[0].certificate_domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main[0].zone_id
}

# ACM 인증서 검증 대기
resource "aws_acm_certificate_validation" "main" {
  count                   = var.use_custom_domain ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = module.acm[0].certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

# ============================================================
# 6단계: EC2 인스턴스
# ============================================================

module "ec2" {
  source = "../../modules/ec2"

  project_name        = var.project_name
  environment         = var.environment
  instance_type       = var.ec2_instance_type
  key_name            = var.ec2_key_name
  ami_id              = var.ec2_ami_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  security_group_id   = module.security_groups.ec2_security_group_id
  root_volume_size    = 50 # 운영 환경: 더 큰 스토리지
  uploads_bucket_name = module.s3.uploads_bucket_id
  aws_region          = var.aws_region

  db_host     = module.rds.db_instance_address
  db_port     = module.rds.db_instance_port
  db_name     = var.db_name
  db_username = var.db_username

  server_port         = var.server_port
  cors_allowed_origin = var.use_custom_domain ? "https://www.${var.domain_name}" : "*"

  # Secrets Manager 연동
  secret_arns                = module.secrets_manager.all_secret_arns
  db_credentials_secret_name = module.secrets_manager.db_credentials_secret_name
  jwt_secret_name            = module.secrets_manager.jwt_secret_name
  toss_secret_name           = module.secrets_manager.toss_secret_name

  depends_on = [module.rds, module.secrets_manager]
}

# ============================================================
# 7단계: CloudFront
# ============================================================

module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name                = var.project_name
  environment                 = var.environment
  use_custom_domain           = var.use_custom_domain
  frontend_bucket_domain_name = module.s3.frontend_bucket_domain_name
  admin_bucket_domain_name    = module.s3.admin_bucket_domain_name
  uploads_bucket_domain_name  = module.s3.uploads_bucket_domain_name
  ec2_public_dns              = module.ec2.instance_public_dns
  backend_port                = var.server_port

  # 커스텀 도메인 설정 (use_custom_domain이 true일 때만 사용)
  frontend_domain     = var.use_custom_domain ? "www.${var.domain_name}" : ""
  admin_domain        = var.use_custom_domain ? "admin.${var.domain_name}" : ""
  api_domain          = var.use_custom_domain ? "api.${var.domain_name}" : ""
  cdn_domain          = var.use_custom_domain ? "cdn.${var.domain_name}" : ""
  acm_certificate_arn = var.use_custom_domain ? aws_acm_certificate_validation.main[0].certificate_arn : null

  price_class = "PriceClass_200" # 아시아, 유럽, 북미

  depends_on = [module.ec2]
}

# ============================================================
# 8단계: Route53 레코드 (커스텀 도메인 사용 시에만)
# ============================================================

locals {
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2" # CloudFront 전역 호스팅 영역 ID
}

# A 레코드 - 프론트엔드 (www)
resource "aws_route53_record" "frontend" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# AAAA 레코드 - 프론트엔드 (IPv6)
resource "aws_route53_record" "frontend_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# A 레코드 - 관리자 (admin)
resource "aws_route53_record" "admin" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "admin.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.admin_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# AAAA 레코드 - 관리자 (IPv6)
resource "aws_route53_record" "admin_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "admin.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.admin_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# A 레코드 - API
resource "aws_route53_record" "api" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.api_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# AAAA 레코드 - API (IPv6)
resource "aws_route53_record" "api_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.api_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# A 레코드 - CDN
resource "aws_route53_record" "cdn" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "cdn.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# AAAA 레코드 - CDN (IPv6)
resource "aws_route53_record" "cdn_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "cdn.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# ============================================================
# 9단계: S3 버킷 정책 (CloudFront 생성 후)
# ============================================================

# S3 버킷 정책 - CloudFront OAC용 (프론트엔드)
resource "aws_s3_bucket_policy" "frontend" {
  bucket = module.s3.frontend_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3.frontend_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.frontend_distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [module.cloudfront]
}

# S3 버킷 정책 - CloudFront OAC용 (관리자)
resource "aws_s3_bucket_policy" "admin" {
  bucket = module.s3.admin_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3.admin_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.admin_distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [module.cloudfront]
}

# S3 버킷 정책 - CloudFront OAC용 (업로드)
resource "aws_s3_bucket_policy" "uploads" {
  bucket = module.s3.uploads_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3.uploads_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.uploads_distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [module.cloudfront]
}
