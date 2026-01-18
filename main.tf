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
