output "db_instance_id" {
  description = "RDS 인스턴스 ID"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "RDS 인스턴스 엔드포인트"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "RDS 인스턴스 주소"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "RDS 인스턴스 포트"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "데이터베이스 이름"
  value       = aws_db_instance.main.db_name
}

output "db_master_username" {
  description = "마스터 사용자 이름"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_identifier" {
  description = "RDS 인스턴스 식별자"
  value       = aws_db_instance.main.identifier
}


