output "frontend_bucket_id" {
  description = "프론트엔드 S3 버킷 ID"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "프론트엔드 S3 버킷 ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_domain_name" {
  description = "프론트엔드 S3 버킷 도메인 이름"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "admin_bucket_id" {
  description = "관리자 S3 버킷 ID"
  value       = aws_s3_bucket.admin.id
}

output "admin_bucket_arn" {
  description = "관리자 S3 버킷 ARN"
  value       = aws_s3_bucket.admin.arn
}

output "admin_bucket_domain_name" {
  description = "관리자 S3 버킷 도메인 이름"
  value       = aws_s3_bucket.admin.bucket_regional_domain_name
}

output "uploads_bucket_id" {
  description = "업로드 S3 버킷 ID"
  value       = aws_s3_bucket.uploads.id
}

output "uploads_bucket_arn" {
  description = "업로드 S3 버킷 ARN"
  value       = aws_s3_bucket.uploads.arn
}

output "uploads_bucket_domain_name" {
  description = "업로드 S3 버킷 도메인 이름"
  value       = aws_s3_bucket.uploads.bucket_regional_domain_name
}


