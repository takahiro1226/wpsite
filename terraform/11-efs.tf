# EFS (Elastic File System)
# WordPress on AWS Infrastructure
# プラグインとテーマの共有ストレージ

#--------------------------------------------------------------
# EFS File System
#--------------------------------------------------------------

resource "aws_efs_file_system" "wordpress" {
  creation_token = "${local.name_prefix}-wordpress-efs"
  encrypted      = true

  # Performance settings
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Lifecycle management (cost optimization)
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-wordpress-efs"
    }
  )
}

#--------------------------------------------------------------
# EFS Mount Targets (in Private Subnets)
#--------------------------------------------------------------

resource "aws_efs_mount_target" "wordpress" {
  count = length(var.availability_zones)

  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

#--------------------------------------------------------------
# EFS Access Point for WordPress Plugins
#--------------------------------------------------------------

resource "aws_efs_access_point" "wordpress_plugins" {
  file_system_id = aws_efs_file_system.wordpress.id

  posix_user {
    gid = 33 # www-data group
    uid = 33 # www-data user
  }

  root_directory {
    path = "/plugins"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "0755"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-wordpress-plugins-ap"
    }
  )
}

#--------------------------------------------------------------
# EFS Access Point for WordPress Themes
#--------------------------------------------------------------

resource "aws_efs_access_point" "wordpress_themes" {
  file_system_id = aws_efs_file_system.wordpress.id

  posix_user {
    gid = 33 # www-data group
    uid = 33 # www-data user
  }

  root_directory {
    path = "/themes"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "0755"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-wordpress-themes-ap"
    }
  )
}

#--------------------------------------------------------------
# CloudWatch Alarms for EFS
#--------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance" {
  alarm_name          = "${local.name_prefix}-efs-burst-credit-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000000000000" # 1TB in bytes
  alarm_description   = "EFS burst credit balance is low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FileSystemId = aws_efs_file_system.wordpress.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "efs_client_connections" {
  alarm_name          = "${local.name_prefix}-efs-client-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ClientConnections"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "High number of EFS client connections"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FileSystemId = aws_efs_file_system.wordpress.id
  }

  tags = local.common_tags
}
