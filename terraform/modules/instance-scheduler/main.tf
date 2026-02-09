# ─── IAM Role for EventBridge Scheduler ───

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-${var.environment}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-scheduler-role"
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${var.project_name}-${var.environment}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${var.ec2_instance_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Resource = "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:${var.rds_instance_identifier}"
      }
    ]
  })
}

# ─── Schedule Group ───

resource "aws_scheduler_schedule_group" "this" {
  name = "${var.project_name}-${var.environment}-scheduler"

  tags = {
    Name = "${var.project_name}-${var.environment}-scheduler"
  }
}

# ─── EC2 Start Schedule ───

resource "aws_scheduler_schedule" "ec2_start" {
  name       = "${var.project_name}-${var.environment}-ec2-start"
  group_name = aws_scheduler_schedule_group.this.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.start_cron
  schedule_expression_timezone = var.timezone

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = [var.ec2_instance_id]
    })
  }
}

# ─── EC2 Stop Schedule ───

resource "aws_scheduler_schedule" "ec2_stop" {
  name       = "${var.project_name}-${var.environment}-ec2-stop"
  group_name = aws_scheduler_schedule_group.this.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.stop_cron
  schedule_expression_timezone = var.timezone

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = [var.ec2_instance_id]
    })
  }
}

# ─── RDS Start Schedule (EC2보다 5분 먼저) ───

resource "aws_scheduler_schedule" "rds_start" {
  name       = "${var.project_name}-${var.environment}-rds-start"
  group_name = aws_scheduler_schedule_group.this.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.rds_start_cron
  schedule_expression_timezone = var.timezone

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      DbInstanceIdentifier = var.rds_instance_identifier
    })
  }
}

# ─── RDS Stop Schedule ───

resource "aws_scheduler_schedule" "rds_stop" {
  name       = "${var.project_name}-${var.environment}-rds-stop"
  group_name = aws_scheduler_schedule_group.this.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.stop_cron
  schedule_expression_timezone = var.timezone

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      DbInstanceIdentifier = var.rds_instance_identifier
    })
  }
}
