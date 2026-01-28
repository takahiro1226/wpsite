# RDS MySQL Database
# WordPress on AWS Infrastructure

#--------------------------------------------------------------
# Random Password for RDS Master User
#--------------------------------------------------------------

resource "random_password" "db_master_password" {
  length  = 32
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#--------------------------------------------------------------
# AWS Secrets Manager for Database Credentials
#--------------------------------------------------------------

resource "aws_secretsmanager_secret" "db_master_credentials" {
  name_prefix             = "${local.name_prefix}-db-master-"
  description             = "RDS MySQL master user credentials for WordPress"
  recovery_window_in_days = 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-master-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_master_credentials" {
  secret_id = aws_secretsmanager_secret.db_master_credentials.id
  secret_string = jsonencode({
    username            = var.db_username
    password            = random_password.db_master_password.result
    engine              = "mysql"
    host                = aws_db_instance.wordpress.address
    port                = aws_db_instance.wordpress.port
    dbname              = var.db_name
    dbInstanceIdentifier = aws_db_instance.wordpress.id
  })
}

#--------------------------------------------------------------
# RDS Parameter Group (MySQL 8.0 optimized for WordPress)
#--------------------------------------------------------------

resource "aws_db_parameter_group" "wordpress" {
  name_prefix = "${local.name_prefix}-mysql80-"
  family      = "mysql8.0"
  description = "MySQL 8.0 parameter group optimized for WordPress"

  # Character Set (UTF-8)
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_connection"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  # Performance Optimization
  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "max_allowed_packet"
    value = "67108864" # 64MB for large media uploads
  }

  # Query Cache (disabled in MySQL 8.0, but keeping for reference)
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  # Binary Logging (for replication and point-in-time recovery)
  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  # Time Zone
  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-mysql80-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------
# RDS Option Group
#--------------------------------------------------------------

resource "aws_db_option_group" "wordpress" {
  name_prefix              = "${local.name_prefix}-mysql80-"
  option_group_description = "MySQL 8.0 option group for WordPress"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-mysql80-options"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------
# RDS Subnet Group (Already created in 01-vpc.tf)
# Reference: aws_db_subnet_group.main
#--------------------------------------------------------------

#--------------------------------------------------------------
# RDS MySQL Instance (Multi-AZ)
#--------------------------------------------------------------

resource "aws_db_instance" "wordpress" {
  identifier     = "${local.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = var.db_engine_version

  # Instance Configuration
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  max_allocated_storage = 100 # Enable storage autoscaling up to 100GB

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_master_password.result
  port     = 3306

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High Availability
  multi_az = var.db_multi_az

  # Backup Configuration
  backup_retention_period   = var.db_backup_retention_period
  backup_window             = "03:00-04:00" # JST 12:00-13:00 (low traffic)
  maintenance_window        = "mon:04:00-mon:05:00" # JST 13:00-14:00
  delete_automated_backups  = false
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name_prefix}-mysql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Parameter and Option Groups
  parameter_group_name = aws_db_parameter_group.wordpress.name
  option_group_name    = aws_db_option_group.wordpress.name

  # Monitoring and Logging
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  performance_insights_enabled    = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60 # Enhanced monitoring every 60 seconds
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn

  # Protection
  deletion_protection = false # Set to true for production

  # Auto Minor Version Upgrade
  auto_minor_version_upgrade = true

  # Apply Changes
  apply_immediately = false # Apply during maintenance window

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-mysql"
    }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password # Prevent recreation when password is rotated
    ]
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.rds
  ]
}

#--------------------------------------------------------------
# IAM Role for Enhanced Monitoring
#--------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "${local.name_prefix}-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  # Tags removed due to IAM permission constraints
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#--------------------------------------------------------------
# CloudWatch Alarms for RDS
#--------------------------------------------------------------

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is too high"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.wordpress.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-cpu-alarm"
    }
  )
}

# Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.name_prefix}-rds-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2GB in bytes
  alarm_description   = "RDS free storage space is low"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.wordpress.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-storage-alarm"
    }
  )
}

# Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name_prefix}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS database connections are too high"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.wordpress.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-connections-alarm"
    }
  )
}
