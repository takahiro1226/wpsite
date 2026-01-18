resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-wpsite-state-wpsite"

  tags = {
    Name        = "Terraform State Storage"
    Environment = "Management"
  }
}
