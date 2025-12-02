output "frontend_distribution_id" {
  description = "프론트엔드 CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "frontend_distribution_arn" {
  description = "프론트엔드 CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "frontend_distribution_domain_name" {
  description = "프론트엔드 CloudFront Domain Name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "api_distribution_id" {
  description = "API CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.api.id
}

output "api_distribution_arn" {
  description = "API CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.api.arn
}

output "api_distribution_domain_name" {
  description = "API CloudFront Domain Name"
  value       = aws_cloudfront_distribution.api.domain_name
}

output "uploads_distribution_id" {
  description = "업로드 CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.uploads.id
}

output "uploads_distribution_arn" {
  description = "업로드 CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.uploads.arn
}

output "uploads_distribution_domain_name" {
  description = "업로드 CloudFront Domain Name"
  value       = aws_cloudfront_distribution.uploads.domain_name
}

output "private_uploads_distribution_id" {
  description = "비공개 업로드 CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.private_uploads.id
}

output "private_uploads_distribution_arn" {
  description = "비공개 업로드 CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.private_uploads.arn
}

output "private_uploads_distribution_domain_name" {
  description = "비공개 업로드 CloudFront Domain Name"
  value       = aws_cloudfront_distribution.private_uploads.domain_name
}


