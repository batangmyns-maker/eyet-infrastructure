# ============================================================
# Uploads 버킷 (공개 파일용)
# ============================================================
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-${var.environment}-files"

  tags = {
    Name        = "${var.project_name}-${var.environment}-files"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Public File Uploads Storage"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Private Files 버킷 (비공개 파일용 - 결제 후 다운로드)
# ============================================================
resource "aws_s3_bucket" "private_files" {
  bucket = "${var.project_name}-${var.environment}-private-files"

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-files"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Private File Storage - Signed URL Required"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Frontend 버킷
# ============================================================
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-${var.environment}-frontend"

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Frontend Static Hosting"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"  # SPA용 - 모든 경로를 index.html로
  }
}

# ============================================================
# 공통 설정
# ============================================================

# Public Access Block
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "private_files" {
  bucket = aws_s3_bucket.private_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "private_files" {
  bucket = aws_s3_bucket.private_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_files" {
  bucket = aws_s3_bucket.private_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CORS Configuration
resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "Content-Type", "Content-Length"]
    max_age_seconds = 3600
  }
}

# Lifecycle Configuration (업로드 버킷 - 비용 최적화)
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "transition-to-intelligent-tiering"
    status = "Enabled"

    filter {
      prefix = "" # 모든 객체에 적용
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # 모든 객체에 적용
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Lifecycle Configuration (비공개 파일 버킷 - 비용 최적화)
resource "aws_s3_bucket_lifecycle_configuration" "private_files" {
  bucket = aws_s3_bucket.private_files.id

  rule {
    id     = "transition-to-intelligent-tiering"
    status = "Enabled"

    filter {
      prefix = "" # 모든 객체에 적용
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # 모든 객체에 적용
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ============================================================
# Bucket Policy
# ============================================================
# 버킷 정책은 main.tf에서 별도로 관리 (순환 의존성 해결)
# CloudFront/EC2 생성 후 main.tf에서 정책 적용
