# Amazon ECR (Elastic Container Registry)
# WordPress on AWS Infrastructure

#--------------------------------------------------------------
# ECR Repository for WordPress Container Images
#--------------------------------------------------------------

resource "aws_ecr_repository" "wordpress" {
  name                 = "${local.name_prefix}-wordpress"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-wordpress-ecr"
    }
  )
}

#--------------------------------------------------------------
# ECR Lifecycle Policy
#--------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "wordpress" {
  repository = aws_ecr_repository.wordpress.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

#--------------------------------------------------------------
# ECR Repository Policy (Allow ECS to pull images)
#--------------------------------------------------------------

data "aws_iam_policy_document" "ecr_repository_policy" {
  statement {
    sid    = "AllowECSTaskExecutionRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }

  statement {
    sid    = "AllowAccountPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
  }
}

resource "aws_ecr_repository_policy" "wordpress" {
  repository = aws_ecr_repository.wordpress.name
  policy     = data.aws_iam_policy_document.ecr_repository_policy.json
}
