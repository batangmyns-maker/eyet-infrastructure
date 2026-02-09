output "scheduler_role_arn" {
  description = "Scheduler IAM Role ARN"
  value       = aws_iam_role.scheduler.arn
}

output "schedule_group_name" {
  description = "Schedule Group 이름"
  value       = aws_scheduler_schedule_group.this.name
}
