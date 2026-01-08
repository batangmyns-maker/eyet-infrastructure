output "tfstate_bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}

output "tflock_table_name" {
  value = aws_dynamodb_table.tflock.name
}
