# Uploads 버킷
output "uploads_bucket_id" {
  description = "Uploads S3 버킷 ID"
  value       = aws_s3_bucket.uploads.id
}

output "uploads_bucket_arn" {
  description = "Uploads S3 버킷 ARN"
  value       = aws_s3_bucket.uploads.arn
}

output "uploads_bucket_domain_name" {
  description = "Uploads S3 버킷 도메인 이름"
  value       = aws_s3_bucket.uploads.bucket_regional_domain_name
}

# Frontend 버킷
output "frontend_bucket_id" {
  description = "Frontend S3 버킷 ID"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "Frontend S3 버킷 ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_domain_name" {
  description = "Frontend S3 버킷 도메인 이름"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

# Private Files 버킷
output "private_files_bucket_id" {
  description = "Private Files S3 버킷 ID"
  value       = aws_s3_bucket.private_files.id
}

output "private_files_bucket_arn" {
  description = "Private Files S3 버킷 ARN"
  value       = aws_s3_bucket.private_files.arn
}

output "private_files_bucket_domain_name" {
  description = "Private Files S3 버킷 도메인 이름"
  value       = aws_s3_bucket.private_files.bucket_regional_domain_name
}
