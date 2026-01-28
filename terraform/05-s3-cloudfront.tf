# S3 and CloudFront CDN
# WordPress on AWS Infrastructure

#--------------------------------------------------------------
# S3 Bucket for WordPress Media Files
#--------------------------------------------------------------

resource "aws_s3_bucket" "media" {
  bucket_prefix = "${var.s3_media_bucket_prefix}-"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-media-bucket"
    }
  )
}

# Enable versioning for media files
resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rule to clean up old versions and incomplete multipart uploads
resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Enable CORS for direct uploads from WordPress
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["https://${var.subdomain}.${var.domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

#--------------------------------------------------------------
# CloudFront Origin Access Control (OAC)
#--------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "media" {
  name                              = "${local.name_prefix}-s3-oac"
  description                       = "OAC for S3 media bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#--------------------------------------------------------------
# CloudFront Distribution
#--------------------------------------------------------------

resource "aws_cloudfront_distribution" "media" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for WordPress media files"
  default_root_object = ""
  price_class         = "PriceClass_200" # US, Europe, Asia, Middle East, and Africa

  # Origin: S3 Bucket
  origin {
    domain_name              = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.media.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.media.id
  }

  # Default Cache Behavior
  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.media.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Use Managed Cache Policy (CachingOptimized)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # Use Managed Origin Request Policy (CORS-S3Origin)
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  # Cache Behavior for images (longer TTL)
  ordered_cache_behavior {
    path_pattern           = "*.jpg"
    target_origin_id       = "S3-${aws_s3_bucket.media.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Use Managed Cache Policy (CachingOptimized)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # Use Managed Origin Request Policy (CORS-S3Origin)
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  ordered_cache_behavior {
    path_pattern           = "*.jpeg"
    target_origin_id       = "S3-${aws_s3_bucket.media.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  ordered_cache_behavior {
    path_pattern           = "*.png"
    target_origin_id       = "S3-${aws_s3_bucket.media.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  ordered_cache_behavior {
    path_pattern           = "*.gif"
    target_origin_id       = "S3-${aws_s3_bucket.media.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  ordered_cache_behavior {
    path_pattern           = "*.webp"
    target_origin_id       = "S3-${aws_s3_bucket.media.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  # Geo Restriction (none)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Custom Error Responses
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-media-cdn"
    }
  )
}

#--------------------------------------------------------------
# S3 Bucket Policy for CloudFront OAC
#--------------------------------------------------------------

data "aws_iam_policy_document" "media_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.media.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.media.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "media" {
  bucket = aws_s3_bucket.media.id
  policy = data.aws_iam_policy_document.media_bucket_policy.json
}

#--------------------------------------------------------------
# IAM Policy for ECS Tasks to Access S3
#--------------------------------------------------------------

resource "aws_iam_policy" "ecs_s3_media_access" {
  name_prefix = "${local.name_prefix}-ecs-s3-media-"
  description = "Allow ECS tasks to read/write S3 media bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.media.arn,
          "${aws_s3_bucket.media.arn}/*"
        ]
      }
    ]
  })

  # Tags removed due to IAM permission constraints
}

#--------------------------------------------------------------
# CloudWatch Alarms for CloudFront
#--------------------------------------------------------------

# 4xx Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_error_rate" {
  alarm_name          = "${local.name_prefix}-cloudfront-4xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "CloudFront 4xx error rate is too high"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    DistributionId = aws_cloudfront_distribution.media.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cloudfront-4xx-alarm"
    }
  )
}

# 5xx Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_error_rate" {
  alarm_name          = "${local.name_prefix}-cloudfront-5xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "CloudFront 5xx error rate is too high"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    DistributionId = aws_cloudfront_distribution.media.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cloudfront-5xx-alarm"
    }
  )
}
