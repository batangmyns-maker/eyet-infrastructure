terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "local"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  bucket_name = "${var.project_name}-local-uploads"
}

resource "aws_s3_bucket" "local_uploads" {
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Environment = "local"
    Project     = var.project_name
    Purpose     = "Local File Upload Testing"
  }
}

resource "aws_s3_bucket_public_access_block" "local_uploads" {
  bucket = aws_s3_bucket.local_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "local_uploads" {
  bucket = aws_s3_bucket.local_uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "local_uploads" {
  bucket = aws_s3_bucket.local_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "local_uploads" {
  bucket = aws_s3_bucket.local_uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "Content-Type", "Content-Length"]
    max_age_seconds = 3600
  }
}

output "local_uploads_bucket_name" {
  description = "로컬 업로드 테스트 버킷 이름"
  value       = aws_s3_bucket.local_uploads.bucket
}

output "local_uploads_bucket_arn" {
  description = "로컬 업로드 테스트 버킷 ARN"
  value       = aws_s3_bucket.local_uploads.arn
}


