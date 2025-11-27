# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group-public"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-pg-params"
  family = "postgres16"

  # 성능 최적화 파라미터 (static parameters는 pending-reboot 필요)
  parameter {
    name         = "shared_buffers"
    value        = "{DBInstanceClassMemory/4096}"  # 메모리의 25%
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "work_mem"
    value = "4096"  # 4MB
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "65536"  # 64MB
  }

  parameter {
    name         = "effective_cache_size"
    value        = "{DBInstanceClassMemory/2048}"  # 메모리의 50%
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "random_page_cost"
    value = "1.1"  # SSD 최적화
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # 1초 이상 쿼리 로깅
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-pg-params"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version

  # 인스턴스 설정
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # 데이터베이스 설정
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = 5432

  # 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = var.publicly_accessible

  # 백업 설정
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"  # UTC 기준 (한국 시간 12:00-13:00)
  maintenance_window      = "mon:04:00-mon:05:00"  # UTC 기준 (한국 시간 월요일 13:00-14:00)

  # 고가용성 설정
  multi_az               = var.multi_az
  deletion_protection    = var.deletion_protection
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # 파라미터 그룹
  parameter_group_name = aws_db_parameter_group.main.name

  # 모니터링
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  # Enhanced Monitoring은 별도 IAM Role 필요, 기본은 비활성화
  monitoring_interval             = var.monitoring_role_arn != null ? 60 : 0
  monitoring_role_arn             = var.monitoring_role_arn

  # Performance Insights
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  # 자동 마이너 버전 업그레이드
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarm - CPU 사용률
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-cpu-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarm - 연결 수
resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS connections"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-connections-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}


