# Outputs
# WordPress on AWS Infrastructure

# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
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

# NAT Instance Outputs
output "nat_instance_ids" {
  description = "NAT instance IDs"
  value       = aws_instance.nat[*].id
}

output "nat_instance_public_ips" {
  description = "NAT instance public IPs"
  value       = aws_eip.nat[*].public_ip
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS primary endpoint"
  value       = aws_db_instance.primary.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.primary.db_name
}

output "rds_multi_az" {
  description = "RDS Multi-AZ enabled"
  value       = aws_db_instance.primary.multi_az
}

# S3 Outputs
output "s3_media_bucket_name" {
  description = "S3 media bucket name"
  value       = aws_s3_bucket.media.id
}

output "s3_media_bucket_arn" {
  description = "S3 media bucket ARN"
  value       = aws_s3_bucket.media.arn
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.media.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.media.domain_name
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.wordpress.repository_url
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.wordpress.name
}

# ALB Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "wordpress_url" {
  description = "WordPress URL"
  value       = "https://${var.subdomain}.${var.domain_name}"
}

# ACM Outputs
output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}

# Secrets Manager Outputs
output "db_password_secret_arn" {
  description = "Database password secret ARN"
  value       = aws_secretsmanager_secret.db_password.arn
  sensitive   = true
}

# IAM Outputs
output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}

# Summary Output
output "deployment_summary" {
  description = "Deployment summary"
  value = <<-EOT
    
    ========================================
    WordPress on AWS - Deployment Complete
    ========================================
    
    WordPress URL: https://${var.subdomain}.${var.domain_name}
    
    Infrastructure:
    - VPC: ${aws_vpc.main.id}
    - ALB: ${aws_lb.main.dns_name}
    - ECS Cluster: ${aws_ecs_cluster.main.name}
    - RDS Endpoint: ${aws_db_instance.primary.endpoint}
    - S3 Bucket: ${aws_s3_bucket.media.id}
    - CloudFront: ${aws_cloudfront_distribution.media.domain_name}
    - ECR: ${aws_ecr_repository.wordpress.repository_url}
    
    Next Steps:
    1. Build and push Docker image to ECR
    2. Update ECS service to use new image
    3. Configure WordPress via web interface
    4. Enable Bedrock plugin in WordPress admin
    
    ========================================
  EOT
}
