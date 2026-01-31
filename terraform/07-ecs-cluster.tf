# Amazon ECS Cluster and Task Definition
# WordPress on AWS Infrastructure

#--------------------------------------------------------------
# ECS Cluster
#--------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-cluster"
    }
  )
}

#--------------------------------------------------------------
# CloudWatch Log Group for ECS Tasks
#--------------------------------------------------------------

resource "aws_cloudwatch_log_group" "wordpress" {
  name              = "/ecs/${local.name_prefix}-wordpress"
  retention_in_days = 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-wordpress-logs"
    }
  )
}

#--------------------------------------------------------------
# IAM Role for ECS Task Execution
#--------------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution" {
  name_prefix = "${local.name_prefix}-ecs-task-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  # Tags removed due to IAM permission constraints
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name_prefix = "${local.name_prefix}-ecs-secrets-"
  role        = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_master_credentials.arn
        ]
      }
    ]
  })
}

#--------------------------------------------------------------
# IAM Role for ECS Tasks
#--------------------------------------------------------------

resource "aws_iam_role" "ecs_task" {
  name_prefix = "${local.name_prefix}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  # Tags removed due to IAM permission constraints
}

# Attach S3 media access policy
resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_s3_media_access.arn
}

# Custom policy for CloudWatch Logs
resource "aws_iam_role_policy" "ecs_task_logs" {
  name_prefix = "${local.name_prefix}-ecs-logs-"
  role        = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.wordpress.arn}:*"
      }
    ]
  })
}

#--------------------------------------------------------------
# ECS Task Definition
#--------------------------------------------------------------

resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${local.name_prefix}-wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  # EFS Volumes
  volume {
    name = "wordpress-plugins"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wordpress.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.wordpress_plugins.id
        iam             = "DISABLED"
      }
    }
  }

  volume {
    name = "wordpress-themes"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wordpress.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.wordpress_themes.id
        iam             = "DISABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "${aws_ecr_repository.wordpress.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      # EFS Mount Points
      mountPoints = [
        {
          sourceVolume  = "wordpress-plugins"
          containerPath = "/var/www/html/wp-content/plugins"
          readOnly      = false
        },
        {
          sourceVolume  = "wordpress-themes"
          containerPath = "/var/www/html/wp-content/themes"
          readOnly      = false
        }
      ]

      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = aws_db_instance.wordpress.address
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.db_name
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = var.db_username
        },
        {
          name  = "WORDPRESS_TABLE_PREFIX"
          value = "wp_"
        },
        {
          name  = "AWS_S3_BUCKET"
          value = aws_s3_bucket.media.id
        },
        {
          name  = "AWS_S3_REGION"
          value = var.aws_region
        },
        {
          name  = "CLOUDFRONT_DOMAIN"
          value = aws_cloudfront_distribution.media.domain_name
        }
      ]

      secrets = [
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_master_credentials.arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wordpress.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "wordpress"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-wordpress-task"
    }
  )
}
