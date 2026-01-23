terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  dynamic "assume_role" {
    for_each = var.terraform_role_arn == null ? [] : [var.terraform_role_arn]
    content {
      role_arn = assume_role.value
    }
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile

  dynamic "assume_role" {
    for_each = var.terraform_role_arn == null ? [] : [var.terraform_role_arn]
    content {
      role_arn = assume_role.value
    }
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  effective_cloudfront_key_group_id = var.cloudfront_key_group_id != null ? var.cloudfront_key_group_id : try(aws_cloudfront_key_group.signed_url[0].id, null)
  effective_cloudfront_key_pair_id  = var.cloudfront_key_pair_id != null ? var.cloudfront_key_pair_id : try(aws_cloudfront_public_key.signed_url[0].id, "")
}

resource "aws_cloudfront_public_key" "signed_url" {
  count    = var.cloudfront_key_pair_id == null && var.cloudfront_public_key != null ? 1 : 0
  provider = aws.us_east_1

  name        = "${var.project_name}-${var.environment}-signed-url"
  encoded_key = var.cloudfront_public_key
}

resource "aws_cloudfront_key_group" "signed_url" {
  count    = var.cloudfront_key_group_id == null && var.cloudfront_public_key != null ? 1 : 0
  provider = aws.us_east_1

  name  = "${var.project_name}-${var.environment}-signed-url"
  items = [aws_cloudfront_public_key.signed_url[0].id]
}

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

  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  vpc_cidr                 = var.vpc_cidr
  app_port                 = var.server_port
  allowed_ssh_cidrs        = []
  allowed_rds_public_cidrs = var.trusted_operator_cidrs
}

module "rds" {
  source = "../../modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  subnet_ids              = module.vpc.public_subnet_ids
  security_group_id       = module.security_groups.rds_security_group_id
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  publicly_accessible     = true
  backup_retention_period = 7
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  performance_insights_enabled = false
  monitoring_role_arn     = null
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project_name            = var.project_name
  environment             = var.environment
  db_host                 = module.rds.db_instance_address
  db_port                 = module.rds.db_instance_port
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  jwt_secret_key          = var.jwt_secret_key
  toss_secret_key         = var.toss_secret_key
  toss_security_key       = var.toss_security_key
  toss_billing_secret_key   = var.toss_billing_secret_key
  toss_billing_security_key = var.toss_billing_security_key
  openai_api_key          = var.openai_api_key
  cloudfront_private_key  = var.cloudfront_private_key
  identity_verification_key_file_password = var.identity_verification_key_file_password
  identity_verification_client_prefix     = var.identity_verification_client_prefix
  identity_verification_encryption_key    = var.identity_verification_encryption_key
  google_oauth_client_secret              = var.google_oauth_client_secret

  depends_on = [module.rds]
}

module "s3" {
  source = "../../modules/s3"

  project_name            = var.project_name
  environment             = var.environment
  cors_allowed_origins    = var.cors_allowed_origins
  trusted_operator_cidrs  = var.trusted_operator_cidrs

  cloudfront_frontend_distribution_arn = ""
  cloudfront_uploads_distribution_arn  = ""
  ec2_role_arn                         = ""
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.project_name}-${var.environment}-cloudfront-logs"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront-logs"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "CloudFront Standard Access Logs"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket" "file_transfer" {
  bucket = "${var.project_name}-${var.environment}-file-transfer"

  tags = {
    Name        = "${var.project_name}-${var.environment}-file-transfer"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "File Transfer Local to EC2"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "file_transfer" {
  bucket = aws_s3_bucket.file_transfer.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "file_transfer" {
  bucket = aws_s3_bucket.file_transfer.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "file_transfer" {
  bucket = aws_s3_bucket.file_transfer.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "file_transfer" {
  bucket = aws_s3_bucket.file_transfer.id

  rule {
    id     = "expire-old-files"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket" "deploy_artifacts" {
  bucket = "${var.project_name}-backend-${var.environment}-deploy-artifacts"

  tags = {
    Name        = "${var.project_name}-backend-${var.environment}-deploy-artifacts"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Deploy Artifacts CI to EC2"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

module "acm" {
  source = "../../modules/acm"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment
  domain_name  = "dev.${var.domain_name}"

  subject_alternative_names = [
    "dev.${var.domain_name}",
    "dev.www.${var.domain_name}",
    "dev.api.${var.domain_name}",
    "dev.cdn.${var.domain_name}",
    "dev.private-cdn.${var.domain_name}"
  ]
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in module.acm.certificate_domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.us_east_1
  certificate_arn         = module.acm.certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

module "ses" {
  count  = var.enable_ses ? 1 : 0
  source = "../../modules/ses"

  project_name             = var.project_name
  environment              = var.environment
  domain_name              = ""
  route53_zone_id          = ""
  verified_email_addresses = var.ses_verified_email_addresses
  enable_dmarc             = var.ses_enable_dmarc
  dmarc_email              = var.ses_dmarc_email
  dmarc_policy             = var.ses_dmarc_policy
}

module "ses_additional_domains" {
  for_each = var.enable_ses ? toset(var.ses_additional_domains) : toset([])
  source   = "../../modules/ses"

  project_name             = var.project_name
  environment              = var.environment
  domain_name              = each.value
  route53_zone_id          = ""
  verified_email_addresses = []
  enable_dmarc             = false
  dmarc_email              = ""
}

resource "aws_cloudwatch_log_group" "bt_portal_backend" {
  name              = "/aws/ec2/bt-portal-backend/${var.environment}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Application = "bt-portal-backend"
    Purpose     = "application-logs"
    Project     = var.project_name
  }
}

resource "aws_ecr_repository" "bt_portal_backend_dev" {
  name                 = "bt-portal-backend-dev"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "bt_portal_backend_dev" {
  repository = aws_ecr_repository.bt_portal_backend_dev.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

module "ec2" {
  source = "../../modules/ec2"

  project_name              = var.project_name
  environment               = var.environment
  instance_type             = var.ec2_instance_type
  key_name                  = null
  ami_id                    = data.aws_ami.al2023.id
  public_subnet_ids         = module.vpc.public_subnet_ids
  security_group_id         = module.security_groups.ec2_security_group_id
  root_volume_size          = 50
  imds_http_put_response_hop_limit = 2
  uploads_bucket_name       = module.s3.uploads_bucket_id
  file_transfer_bucket_name = aws_s3_bucket.file_transfer.id
  deploy_artifacts_bucket_name = aws_s3_bucket.deploy_artifacts.id
  aws_region                = var.aws_region

  db_host     = module.rds.db_instance_address
  db_port     = module.rds.db_instance_port
  db_name     = var.db_name
  db_username = var.db_username

  server_port         = var.server_port
  cors_allowed_origin = "https://dev.www.${var.domain_name}"

  secret_arns                = module.secrets_manager.all_secret_arns
  db_credentials_secret_name = module.secrets_manager.db_credentials_secret_name
  jwt_secret_name            = module.secrets_manager.jwt_secret_name
  toss_secret_name           = module.secrets_manager.toss_secret_name
  cloudfront_private_key_secret_name = module.secrets_manager.cloudfront_private_key_secret_name
  private_files_bucket_name  = module.s3.private_files_bucket_id
  cloudfront_private_distribution_domain = "dev.private-cdn.${var.domain_name}"
  cloudfront_key_pair_id     = local.effective_cloudfront_key_pair_id
  cloudwatch_log_group_arn   = aws_cloudwatch_log_group.bt_portal_backend.arn
  api_domain                 = "dev.api.${var.domain_name}"

  depends_on = [module.rds, module.secrets_manager, aws_cloudwatch_log_group.bt_portal_backend]
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name                     = var.project_name
  environment                      = var.environment
  use_custom_domain                = true
  frontend_bucket_domain_name      = module.s3.frontend_bucket_domain_name
  uploads_bucket_domain_name       = module.s3.uploads_bucket_domain_name
  private_files_bucket_domain_name = module.s3.private_files_bucket_domain_name
  ec2_public_dns                   = module.ec2.instance_public_dns
  backend_port                     = var.cloudfront_backend_port

  frontend_domain    = "dev.www.${var.domain_name}"
  api_domain         = "dev.api.${var.domain_name}"
  cdn_domain         = "dev.cdn.${var.domain_name}"
  root_domain        = "dev.${var.domain_name}"
  private_cdn_domain = "dev.private-cdn.${var.domain_name}"
  acm_certificate_arn = aws_acm_certificate_validation.main.certificate_arn
  api_allowed_origins = var.cors_allowed_origins
  cloudfront_key_group_id = local.effective_cloudfront_key_group_id

  logging_bucket_domain_name = aws_s3_bucket.cloudfront_logs.bucket_domain_name
  logging_prefix             = "cloudfront/"

  trusted_operator_cidrs = var.trusted_operator_cidrs
  enable_ip_whitelist    = true

  enable_api_waf               = false
  api_origin_read_timeout      = 60
  api_origin_keepalive_timeout = 5

  price_class = "PriceClass_200"
}

locals {
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"
}

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "frontend_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "root_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.frontend_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.api_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "api_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.api.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.api_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "cdn" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.cdn.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "cdn_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.cdn.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "private_cdn" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.private-cdn.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.private_uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "private_cdn_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.private-cdn.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.private_uploads_distribution_domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

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
    ]
  })

  depends_on = [module.cloudfront, module.ec2]
}

resource "aws_s3_bucket_policy" "file_transfer" {
  bucket = aws_s3_bucket.file_transfer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
          aws_s3_bucket.file_transfer.arn,
          "${aws_s3_bucket.file_transfer.arn}/*"
        ]
      }
    ]
  })

  depends_on = [module.ec2]
}

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

  depends_on = [module.cloudfront]
}
