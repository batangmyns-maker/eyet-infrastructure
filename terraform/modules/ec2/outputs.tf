output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "EC2 인스턴스 Public IP"
  value       = aws_eip.main.public_ip
}

output "instance_private_ip" {
  description = "EC2 인스턴스 Private IP"
  value       = aws_instance.main.private_ip
}

output "elastic_ip" {
  description = "Elastic IP 주소"
  value       = aws_eip.main.public_ip
}

output "instance_public_dns" {
  description = "EC2 인스턴스 Public DNS 이름"
  value       = aws_instance.main.public_dns
}

output "iam_role_name" {
  description = "EC2 IAM Role 이름"
  value       = aws_iam_role.ec2.name
}

output "iam_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2.arn
}


