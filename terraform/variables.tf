# Variables Definition
# WordPress on AWS Infrastructure

# General
variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "wordpress-bedrock"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "prod"
}

# Network
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

# NAT Instance (Cost Optimization)
variable "nat_instance_type" {
  description = "NAT Instance type"
  type        = string
  default     = "t4g.nano"
}

# RDS
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0.40"
}

variable "db_backup_retention_period" {
  description = "Backup retention period (days)"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

# ECS
variable "ecs_task_cpu" {
  description = "ECS task CPU units"
  type        = string
  default     = "512"  # 0.5 vCPU
}

variable "ecs_task_memory" {
  description = "ECS task memory (MB)"
  type        = string
  default     = "1024"  # 1GB
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 4
}

# Domain
variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "takahiro-work.click"
}

variable "subdomain" {
  description = "Subdomain for WordPress"
  type        = string
  default     = "blog"
}

# S3
variable "s3_media_bucket_prefix" {
  description = "S3 media bucket prefix"
  type        = string
  default     = "wordpress-media"
}

# Bedrock
variable "bedrock_region" {
  description = "Amazon Bedrock region"
  type        = string
  default     = "us-east-1"  # Stable Diffusion XLが利用可能なリージョン
}

variable "bedrock_model_id" {
  description = "Bedrock model ID"
  type        = string
  default     = "stability.stable-diffusion-xl-v1"
}

# Lambda (Image Generation)
variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "wp_user" {
  description = "WordPress username for REST API"
  type        = string
  default     = "admin"
}

variable "wp_app_password" {
  description = "WordPress Application Password (set via environment variable)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "summary_prompt_path" {
  description = "Parameter Store path for summary prompt"
  type        = string
  default     = "/wordpress/prompt/summary"
}

variable "image_prompt_path" {
  description = "Parameter Store path for image generation prompt"
  type        = string
  default     = "/wordpress/prompt/image"
}

# Tags
variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}