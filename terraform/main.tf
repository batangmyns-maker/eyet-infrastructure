terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend 설정 (S3)
  # 기본값: prod 환경
  # 다른 환경 사용 시: terraform init -backend-config="key=test/terraform.tfstate" 등으로 override
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
# 모든 환경 리소스
# ============================================================

# 1단계: 기본 인프라 (VPC, Security Groups)
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  app_port              = var.server_port
  allowed_ssh_cidrs     = var.trusted_operator_cidrs
  allowed_rds_public_cidrs = var.trusted_operator_cidrs
}

# 2단계: 데이터베이스 및 시크릿
module "rds" {
  source = "./modules/rds"

  project_name                 = var.project_name
  environment                  = var.environment
  subnet_ids                   = module.vpc.public_subnet_ids
  security_group_id            = module.security_groups.rds_security_group_id
  instance_class               = var.rds_instance_class
  allocated_storage            = var.rds_allocated_storage
  database_name                = var.db_name
  master_username              = var.db_username
  master_password              = var.db_password
  publicly_accessible          = var.rds_publicly_accessible
  backup_retention_period      = 30
  multi_az                     = false
  deletion_protection          = true
  skip_final_snapshot          = false
  performance_insights_enabled  = true
  monitoring_role_arn          = null
}

module "secrets_manager" {
  source = "./modules/secrets-manager"

  project_name            = var.project_name
  environment             = var.environment
  db_host                 = module.rds.db_instance_address
  db_port                 = module.rds.db_instance_port
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  jwt_secret_key          = var.jwt_secret_key
  toss_secret_key         = var.toss_secret_key
  cloudfront_private_key   = var.cloudfront_private_key

  depends_on = [module.rds]
}

# 3단계: S3 버킷 (모든 환경)
# 순환 의존성 해결: S3 버킷은 먼저 생성, 정책은 CloudFront/EC2 생성 후 별도로 적용
module "s3" {
  source = "./modules/s3"

  project_name         = var.project_name
  environment          = var.environment
  cors_allowed_origins = var.cors_allowed_origins
  trusted_operator_cidrs = var.trusted_operator_cidrs
  
  # Prod 환경에서는 초기에는 빈 값 (정책은 나중에 별도로 적용)
  cloudfront_frontend_distribution_arn = ""
  cloudfront_uploads_distribution_arn  = ""
  ec2_role_arn                         = ""
}

# ============================================================
# Legacy Local 버킷 관리 (환경 변수와 무관한 특수 케이스)
# ============================================================
# 주의: 이 버킷은 environment 변수와 무관하며, legacy 버킷입니다.
# test 환경 추가 시에도 이 버킷은 그대로 유지됩니다.
# import 필요: terraform import aws_s3_bucket.local_files bt-portal-local-files
resource "aws_s3_bucket" "local_files" {
  bucket = "bt-portal-local-files"

  tags = {
    Name        = "bt-portal-local-files"
    Environment = "local"
    Project     = var.project_name
    Purpose     = "Local File Upload Testing"
    ManagedBy   = "Terraform"
  }
}

# Versioning (기존 설정: Enabled)
# terraform import aws_s3_bucket_versioning.local_files bt-portal-local-files
resource "aws_s3_bucket_versioning" "local_files" {
  bucket = aws_s3_bucket.local_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption (기존 설정: AES256)
# terraform import aws_s3_bucket_server_side_encryption_configuration.local_files bt-portal-local-files
resource "aws_s3_bucket_server_side_encryption_configuration" "local_files" {
  bucket = aws_s3_bucket.local_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public Access Block (기존 설정)
# terraform import aws_s3_bucket_public_access_block.local_files bt-portal-local-files
resource "aws_s3_bucket_public_access_block" "local_files" {
  bucket = aws_s3_bucket.local_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS Configuration (기존 설정: localhost:3000, 127.0.0.1:3000)
# terraform import aws_s3_bucket_cors_configuration.local_files bt-portal-local-files
resource "aws_s3_bucket_cors_configuration" "local_files" {
  bucket = aws_s3_bucket.local_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "GET", "HEAD", "DELETE", "PUT"]
    allowed_origins = [
      "http://127.0.0.1:3000",
      "http://localhost:3000"
    ]
    expose_headers  = ["ETag", "Content-Type", "Content-Length"]
    max_age_seconds = 3600
  }
}

# Bucket Policy (기존 설정: IP 기반 접근 제어)
# terraform import aws_s3_bucket_policy.local_files bt-portal-local-files
resource "aws_s3_bucket_policy" "local_files" {
  bucket = aws_s3_bucket.local_files.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowOnlyWhitelistedIps"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.local_files.arn,
          "${aws_s3_bucket.local_files.arn}/*"
        ]
        Condition = {
          IpAddress = {
            "aws:SourceIp" = ["112.222.28.115/32"]
          }
        }
      }
    ]
  })
}

# 4단계: ACM 인증서 (커스텀 도메인 사용 시에만)
module "acm" {
  count  = var.use_custom_domain ? 1 : 0
  source = "./modules/acm"

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

# 5단계: Route53 (커스텀 도메인 사용 시에만)
resource "aws_route53_zone" "main" {
  count = var.use_custom_domain ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-hosted-zone"
    Environment = var.environment
    Project     = var.project_name
  }
}

# 5-1단계: SES (이메일 발송) - 메인 도메인 또는 이메일 주소 인증
module "ses" {
  count  = var.use_custom_domain || length(var.ses_verified_email_addresses) > 0 ? 1 : 0
  source = "./modules/ses"

  project_name             = var.project_name
  environment              = var.environment
  domain_name              = var.use_custom_domain ? var.domain_name : ""
  route53_zone_id          = var.use_custom_domain ? aws_route53_zone.main[0].zone_id : ""
  verified_email_addresses = var.ses_verified_email_addresses
  enable_dmarc             = var.ses_enable_dmarc
  dmarc_email              = var.ses_dmarc_email
  dmarc_policy             = var.ses_dmarc_policy

  depends_on = [aws_route53_zone.main]
}

# 5-2단계: SES - 추가 도메인 인증 (여러 도메인 사용 시)
module "ses_additional_domains" {
  for_each = toset(var.ses_additional_domains)
  source   = "./modules/ses"

  project_name             = var.project_name
  environment              = var.environment
  domain_name              = each.value
  route53_zone_id          = ""  # 추가 도메인은 Route53 레코드 수동 설정 필요
  verified_email_addresses = []
  enable_dmarc             = false
  dmarc_email              = ""
}

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

resource "aws_acm_certificate_validation" "main" {
  count                   = var.use_custom_domain ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = module.acm[0].certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

# 6단계: EC2 인스턴스
module "ec2" {
  source = "./modules/ec2"

  project_name        = var.project_name
  environment         = var.environment
  instance_type       = var.ec2_instance_type
  key_name            = var.ec2_key_name
  ami_id              = var.ec2_ami_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  security_group_id   = module.security_groups.ec2_security_group_id
  root_volume_size    = 50
  uploads_bucket_name = module.s3.uploads_bucket_id
  aws_region          = var.aws_region

  db_host     = module.rds.db_instance_address
  db_port     = module.rds.db_instance_port
  db_name     = var.db_name
  db_username = var.db_username

  server_port         = var.server_port
  cors_allowed_origin = var.use_custom_domain ? "https://www.${var.domain_name}" : "*"

  secret_arns                         = module.secrets_manager.all_secret_arns
  db_credentials_secret_name          = module.secrets_manager.db_credentials_secret_name
  jwt_secret_name                     = module.secrets_manager.jwt_secret_name
  toss_secret_name                    = module.secrets_manager.toss_secret_name
  cloudfront_private_key_secret_name  = module.secrets_manager.cloudfront_private_key_secret_name
  private_files_bucket_name           = module.s3.private_files_bucket_id
  # CloudFront 도메인은 커스텀 도메인 사용 시 직접 계산, 아니면 나중에 환경 변수로 설정
  cloudfront_private_distribution_domain = var.use_custom_domain ? "private-cdn.${var.domain_name}" : ""
  cloudfront_key_pair_id              = var.cloudfront_key_pair_id

  depends_on = [module.rds, module.secrets_manager]
}

# 7단계: CloudFront
module "cloudfront" {
  source = "./modules/cloudfront"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name                     = var.project_name
  environment                      = var.environment
  use_custom_domain                = var.use_custom_domain
  frontend_bucket_domain_name      = module.s3.frontend_bucket_domain_name
  uploads_bucket_domain_name       = module.s3.uploads_bucket_domain_name
  private_files_bucket_domain_name = module.s3.private_files_bucket_domain_name
  ec2_public_dns                   = module.ec2.instance_public_dns
  backend_port                     = var.cloudfront_backend_port

  frontend_domain     = var.use_custom_domain ? "www.${var.domain_name}" : ""
  api_domain          = var.use_custom_domain ? "api.${var.domain_name}" : ""
  cdn_domain          = var.use_custom_domain ? "cdn.${var.domain_name}" : ""
  root_domain         = var.use_custom_domain ? var.domain_name : ""
  private_cdn_domain  = var.use_custom_domain ? "private-cdn.${var.domain_name}" : ""
  acm_certificate_arn = var.use_custom_domain ? aws_acm_certificate_validation.main[0].certificate_arn : null
  api_allowed_origins  = var.cors_allowed_origins
  cloudfront_key_group_id = var.cloudfront_key_group_id

  # IP 화이트리스트 설정
  trusted_operator_cidrs = var.trusted_operator_cidrs
  enable_ip_whitelist     = true  # 필요시 변수로 제어 가능

  price_class = "PriceClass_200"
}

# 8단계: Route53 레코드 (커스텀 도메인 사용 시에만)
locals {
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"
}

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

resource "aws_route53_record" "root" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "root_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

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

resource "aws_route53_record" "private_cdn" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "private-cdn.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.private_uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "private_cdn_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = "private-cdn.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.private_uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# 9단계: S3 버킷 정책 (CloudFront/EC2 생성 후)
# 순환 의존성 해결: S3 버킷 정책을 별도로 관리
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

resource "aws_s3_bucket_policy" "uploads" {
  bucket = module.s3.uploads_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
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
        },
        {
          Sid    = "AllowBackendEc2RoleAccess"
          Effect = "Allow"
          Principal = {
            AWS = module.ec2.iam_role_arn
          }
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            module.s3.uploads_bucket_arn,
            "${module.s3.uploads_bucket_arn}/*"
          ]
        }
      ],
      length(var.trusted_operator_cidrs) > 0 ? [
        {
          Sid       = "AllowWhitelistedIpAccess"
          Effect    = "Allow"
          Principal = "*"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            module.s3.uploads_bucket_arn,
            "${module.s3.uploads_bucket_arn}/*"
          ]
          Condition = {
            IpAddress = {
              "aws:SourceIp" = var.trusted_operator_cidrs
            }
          }
        }
      ] : []
    )
  })

  depends_on = [module.cloudfront, module.ec2]
}

# 비공개 파일 버킷 정책 (CloudFront/EC2 생성 후)
resource "aws_s3_bucket_policy" "private_files" {
  bucket = module.s3.private_files_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPrivateCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3.private_files_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.private_uploads_distribution_arn
          }
        }
      },
      {
        Sid    = "AllowBackendEc2RoleAccess"
        Effect = "Allow"
        Principal = {
          AWS = module.ec2.iam_role_arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3.private_files_bucket_arn,
          "${module.s3.private_files_bucket_arn}/*"
        ]
      }
    ]
  })

  depends_on = [module.cloudfront, module.ec2]
}

