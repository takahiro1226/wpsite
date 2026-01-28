terraform {
  # (A) .terraform-version と一致、または範囲を合わせる
  required_version = ">= 1.10.0" 

  # (B) AWS Provider の指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }  
}
provider "aws" {
    region = "ap-northeast-1"
    default_tags {  # ← 追加
      tags = {
        Project     = "WordPress-Bedrock"
        Environment = "production"
        ManagedBy   = "Terraform"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "my-terraform-wpsite-state-wpsite"
    key    = "network/terraform.tfstate" # S3内での保存パス
    region = "ap-northeast-1"
  }
}

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local Variables
locals {
  account_id = data.aws_caller_identity.current.account_id
  region = data.aws_region.current.id
  # Naming Convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common Tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}