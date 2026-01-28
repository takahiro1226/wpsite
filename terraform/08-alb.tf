# Application Load Balancer
# WordPress on AWS Infrastructure

#--------------------------------------------------------------
# Application Load Balancer
#--------------------------------------------------------------

# resource "aws_lb" "main" {
#   name               = "${local.name_prefix}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = aws_subnet.public[*].id

#   enable_deletion_protection = false
#   enable_http2               = true
#   enable_cross_zone_load_balancing = true

#   # Access logs disabled (can be enabled by creating S3 bucket for logs)
#   # access_logs {
#   #   enabled = true
#   #   bucket  = aws_s3_bucket.alb_logs.id
#   #   prefix  = "alb"
#   # }

#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.name_prefix}-alb"
#     }
#   )
# }

#--------------------------------------------------------------
# Target Group for ECS Tasks
#--------------------------------------------------------------

resource "aws_lb_target_group" "wordpress" {
  name_prefix = "wp-"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-wordpress-tg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------
# ALB Listener (HTTP)
#--------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-http-listener"
    }
  )
}

# Note: HTTPS listener will be added in Phase 10 (Route53 & ACM)
# after SSL certificate is provisioned

#--------------------------------------------------------------
# CloudWatch Alarms for ALB
#--------------------------------------------------------------

# Target Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${local.name_prefix}-alb-target-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "ALB target response time is too high"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-response-time-alarm"
    }
  )
}

# Unhealthy Target Count Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_target_count" {
  alarm_name          = "${local.name_prefix}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "ALB has unhealthy targets"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.wordpress.arn_suffix
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-unhealthy-alarm"
    }
  )
}

# HTTP 5xx Error Count Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB is receiving too many 5xx errors from targets"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-5xx-alarm"
    }
  )
}
