# Outputs - Phase 2: VPC and Network
# WordPress on AWS Infrastructure

# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "Database route table IDs"
  value       = aws_route_table.database[*].id
}

# Phase 2 Summary
output "phase2_summary" {
  description = "Phase 2 deployment summary"
  value = <<-EOT
    
    ========================================
    Phase 2: VPC and Network - Complete
    ========================================
    
    VPC Configuration:
    - VPC ID: ${aws_vpc.main.id}
    - CIDR: ${aws_vpc.main.cidr_block}
    - Internet Gateway: ${aws_internet_gateway.main.id}
    
    Subnets:
    - Public Subnets: ${length(aws_subnet.public)} (${join(", ", aws_subnet.public[*].id)})
    - Private Subnets: ${length(aws_subnet.private)} (${join(", ", aws_subnet.private[*].id)})
    - Database Subnets: ${length(aws_subnet.database)} (${join(", ", aws_subnet.database[*].id)})
    
    Next Steps:
    - Phase 3: Create Security Groups and NAT Instances
    
    ========================================
  EOT
}

# ============================================
# Phase 3: Security Groups and NAT Instance Outputs
# ============================================

# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS security group ID"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "nat_security_group_id" {
  description = "NAT instance security group ID"
  value       = aws_security_group.nat.id
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

# NAT Instance Outputs
output "nat_instance_ids" {
  description = "NAT instance IDs"
  value       = aws_instance.nat[*].id
}

output "nat_instance_public_ips" {
  description = "NAT instance public IPs"
  value       = aws_eip.nat[*].public_ip
}

output "phase3_summary" {
  description = "Phase 3 deployment summary"
  value = <<-EOT

    ========================================
    Phase 3: Security Groups & NAT - Complete
    ========================================

    Security Groups:
    - ALB SG: ${aws_security_group.alb.id}
    - ECS SG: ${aws_security_group.ecs.id}
    - RDS SG: ${aws_security_group.rds.id}
    - NAT SG: ${aws_security_group.nat.id}
    - Lambda SG: ${aws_security_group.lambda.id}

    NAT Instances:
    - Instance Type: ${var.nat_instance_type}
    - Instance IDs: ${join(", ", aws_instance.nat[*].id)}
    - Public IPs: ${join(", ", aws_eip.nat[*].public_ip)}

    Cost Savings:
    - Using NAT Instances (~$6/month) instead of NAT Gateway (~$64/month)
    - Estimated monthly savings: ~$58

    Next Steps:
    - Phase 4: Create RDS MySQL Database

    ========================================
  EOT
}

# ============================================
# Phase 4: RDS MySQL Outputs
# ============================================

output "rds_endpoint" {
  description = "RDS primary endpoint"
  value       = aws_db_instance.wordpress.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS instance address"
  value       = aws_db_instance.wordpress.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.wordpress.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.wordpress.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = var.db_username
  sensitive   = true
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for database credentials"
  value       = aws_secretsmanager_secret.db_master_credentials.arn
}

output "phase4_summary" {
  description = "Phase 4 deployment summary"
  value = <<-EOT

    ========================================
    Phase 4: RDS MySQL Database - Complete
    ========================================

    Database Configuration:
    - Instance ID: ${aws_db_instance.wordpress.id}
    - Engine: MySQL ${aws_db_instance.wordpress.engine_version}
    - Instance Class: ${var.db_instance_class}
    - Storage: ${var.db_allocated_storage}GB (Auto-scaling up to 100GB)
    - Multi-AZ: ${var.db_multi_az}

    Security:
    - Storage Encrypted: Yes
    - Credentials stored in Secrets Manager
    - Secret ARN: ${aws_secretsmanager_secret.db_master_credentials.arn}

    Monitoring:
    - Enhanced Monitoring: Enabled (60s interval)
    - Performance Insights: Enabled (7 days retention)
    - CloudWatch Logs: error, general, slowquery
    - CloudWatch Alarms: CPU, Storage, Connections

    Backup:
    - Retention Period: ${var.db_backup_retention_period} days
    - Backup Window: 03:00-04:00 UTC (12:00-13:00 JST)
    - Maintenance Window: Mon 04:00-05:00 UTC (13:00-14:00 JST)

    Next Steps:
    - Phase 5: Create S3 Bucket and CloudFront

    ========================================
  EOT
}

# ============================================
# Phase 5: S3 & CloudFront Outputs
# ============================================

output "s3_media_bucket_name" {
  description = "S3 media bucket name"
  value       = aws_s3_bucket.media.id
}

output "s3_media_bucket_arn" {
  description = "S3 media bucket ARN"
  value       = aws_s3_bucket.media.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.media.id
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.media.domain_name
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.media.arn
}

output "ecs_s3_media_policy_arn" {
  description = "IAM policy ARN for ECS S3 media access"
  value       = aws_iam_policy.ecs_s3_media_access.arn
}

output "phase5_summary" {
  description = "Phase 5 deployment summary"
  value = <<-EOT

    ========================================
    Phase 5: S3 & CloudFront CDN - Complete
    ========================================

    S3 Configuration:
    - Bucket Name: ${aws_s3_bucket.media.id}
    - Versioning: Enabled
    - Encryption: AES256
    - Public Access: Blocked
    - CORS: Enabled for ${var.subdomain}.${var.domain_name}

    CloudFront Configuration:
    - Distribution ID: ${aws_cloudfront_distribution.media.id}
    - Domain Name: ${aws_cloudfront_distribution.media.domain_name}
    - Price Class: PriceClass_200 (US, Europe, Asia, Middle East, Africa)
    - HTTPS: Enabled (redirect from HTTP)
    - Origin Access: CloudFront OAC

    Features:
    - Image compression enabled
    - Lifecycle policy: Delete old versions after 30 days
    - CloudWatch Alarms: 4xx/5xx error rates
    - ECS IAM policy created for S3 access

    CDN URL: https://${aws_cloudfront_distribution.media.domain_name}

    Next Steps:
    - Phase 6: Create ECR Repository
    - Phase 7: Create ECS Cluster
    - Phase 8: Create ALB
    - Phase 9: Create ECS Service

    ========================================
  EOT
}

# ============================================
# Phase 6: ECR Outputs
# ============================================

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.wordpress.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.wordpress.arn
}

output "phase6_summary" {
  description = "Phase 6 deployment summary"
  value = <<-EOT

    ========================================
    Phase 6: ECR Repository - Complete
    ========================================

    ECR Configuration:
    - Repository Name: ${aws_ecr_repository.wordpress.name}
    - Repository URL: ${aws_ecr_repository.wordpress.repository_url}
    - Image Scanning: Enabled (scan on push)
    - Encryption: AES256

    Lifecycle Policy:
    - Keep last 10 tagged images (v*)
    - Delete untagged images after 7 days

    Next Steps:
    - Build and push WordPress Docker image to ECR
    - Command: docker build -t ${aws_ecr_repository.wordpress.repository_url}:latest .
    - Command: docker push ${aws_ecr_repository.wordpress.repository_url}:latest

    ========================================
  EOT
}

# # ============================================
# # Phase 7: ECS Cluster Outputs
# # ============================================

# output "ecs_cluster_id" {
#   description = "ECS cluster ID"
#   value       = aws_ecs_cluster.main.id
# }

# output "ecs_cluster_arn" {
#   description = "ECS cluster ARN"
#   value       = aws_ecs_cluster.main.arn
# }

# output "ecs_task_definition_arn" {
#   description = "ECS task definition ARN"
#   value       = aws_ecs_task_definition.wordpress.arn
# }

# output "phase7_summary" {
#   description = "Phase 7 deployment summary"
#   value = <<-EOT

#     ========================================
#     Phase 7: ECS Cluster & Task - Complete
#     ========================================

#     ECS Cluster:
#     - Cluster Name: ${aws_ecs_cluster.main.name}
#     - Container Insights: Enabled

#     Task Definition:
#     - Family: ${aws_ecs_task_definition.wordpress.family}
#     - CPU: ${var.ecs_task_cpu} (0.5 vCPU)
#     - Memory: ${var.ecs_task_memory}MB (1GB)
#     - Network Mode: awsvpc

#     IAM Roles:
#     - Task Execution Role: ${aws_iam_role.ecs_task_execution.name}
#     - Task Role: ${aws_iam_role.ecs_task.name}

#     CloudWatch Logs:
#     - Log Group: ${aws_cloudwatch_log_group.wordpress.name}
#     - Retention: 7 days

#     Next Steps:
#     - Phase 8: Create ALB

#     ========================================
#   EOT
# }

# # ============================================
# # Phase 8: ALB Outputs
# # ============================================

# output "alb_dns_name" {
#   description = "ALB DNS name"
#   value       = aws_lb.main.dns_name
# }

# output "alb_arn" {
#   description = "ALB ARN"
#   value       = aws_lb.main.arn
# }

# output "alb_zone_id" {
#   description = "ALB Zone ID for Route53 alias"
#   value       = aws_lb.main.zone_id
# }

# output "target_group_arn" {
#   description = "Target group ARN"
#   value       = aws_lb_target_group.wordpress.arn
# }

# output "phase8_summary" {
#   description = "Phase 8 deployment summary"
#   value = <<-EOT

#     ========================================
#     Phase 8: Application Load Balancer - Complete
#     ========================================

#     ALB Configuration:
#     - Name: ${aws_lb.main.name}
#     - DNS Name: ${aws_lb.main.dns_name}
#     - Type: Application Load Balancer
#     - Subnets: ${length(aws_subnet.public)} public subnets

#     Target Group:
#     - Name: ${aws_lb_target_group.wordpress.name}
#     - Protocol: HTTP
#     - Port: 80
#     - Health Check: / (every 30s)

#     Listeners:
#     - HTTP (80) → Forward to WordPress target group

#     CloudWatch Alarms:
#     - Target response time
#     - Unhealthy target count
#     - 5xx error count

#     Access URL: http://${aws_lb.main.dns_name}

#     Next Steps:
#     - Phase 9: Create ECS Service

#     ========================================
#   EOT
# }

# # ============================================
# # Phase 9: ECS Service Outputs
# # ============================================

# output "ecs_service_name" {
#   description = "ECS service name"
#   value       = aws_ecs_service.wordpress.name
# }

# output "ecs_service_id" {
#   description = "ECS service ID"
#   value       = aws_ecs_service.wordpress.id
# }

# output "phase9_summary" {
#   description = "Phase 9 deployment summary"
#   value = <<-EOT

#     ========================================
#     Phase 9: ECS Service - Complete
#     ========================================

#     ECS Service:
#     - Name: ${aws_ecs_service.wordpress.name}
#     - Launch Type: Fargate
#     - Desired Count: ${var.ecs_desired_count}
#     - Platform Version: LATEST

#     Auto Scaling:
#     - Min Capacity: ${var.ecs_min_capacity}
#     - Max Capacity: ${var.ecs_max_capacity}
#     - CPU Target: 70%
#     - Memory Target: 80%

#     Network:
#     - Subnets: ${length(aws_subnet.private)} private subnets
#     - Security Group: ${aws_security_group.ecs.id}
#     - Public IP: Disabled

#     Load Balancer:
#     - Target Group: ${aws_lb_target_group.wordpress.name}
#     - Container Port: 80

#     Deployment:
#     - Circuit Breaker: Enabled with rollback
#     - Maximum: 200%
#     - Minimum Healthy: 100%

#     CloudWatch Alarms:
#     - CPU utilization > 85%
#     - Memory utilization > 90%
#     - Running task count < minimum

#     WordPress URL: http://${aws_lb.main.dns_name}

#     Next Steps:
#     - Phase 10: Create Route53 DNS and ACM Certificate
#     - Phase 11: Create Lambda for image generation
#     - Phase 12: Create API Gateway webhook

#     ========================================
#   EOT
# }

# # # Phase 10+: Route53, Lambda & API Gateway Outputs
# # output "api_gateway_url" {
# #   description = "API Gateway webhook URL"
# #   value       = "${aws_api_gateway_deployment.prod.invoke_url}${aws_api_gateway_resource.webhook.path}"
# # }