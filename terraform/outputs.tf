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

# # Phase 4: RDS Outputs
# output "rds_endpoint" {
#   description = "RDS primary endpoint"
#   value       = aws_db_instance.primary.endpoint
#   sensitive   = true
# }

# # Phase 5: S3 & CloudFront Outputs
# output "s3_media_bucket_name" {
#   description = "S3 media bucket name"
#   value       = aws_s3_bucket.media.id
# }

# # Phase 6: ECS & ALB Outputs
# output "ecr_repository_url" {
#   description = "ECR repository URL"
#   value       = aws_ecr_repository.wordpress.repository_url
# }

# # Phase 7: Lambda & API Gateway Outputs
# output "api_gateway_url" {
#   description = "API Gateway webhook URL"
#   value       = "${aws_api_gateway_deployment.prod.invoke_url}${aws_api_gateway_resource.webhook.path}"
# }