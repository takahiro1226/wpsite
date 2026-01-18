terraform {
  # (A) .terraform-version と一致、または範囲を合わせる
  required_version = ">= 1.10.0" 

  # (B) AWS Provider の指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" 
    }
  }  
}
provider "aws" {
    region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "my-terraform-wpsite-state-wpsite"
    key    = "network/terraform.tfstate" # S3内での保存パス
    region = "ap-northeast-1"
  }
}

# その下に以前のコードを（VPCを作るなら）復活させます
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform-managed-vpc"
  }
}