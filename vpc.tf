# 1. VPCの作成
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # AWSのDNSサーバーを有効化
  enable_dns_hostnames = true # パブリックIPにホスト名を割り当てる

  tags = {
    Name = "wpsite-vpc"
  }
}