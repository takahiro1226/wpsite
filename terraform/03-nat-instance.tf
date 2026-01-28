# NAT Instance (Cost-Optimized Alternative to NAT Gateway)
# WordPress on AWS Infrastructure

#--------------------------------------------------------------
# Latest Amazon Linux 2023 AMI (ARM64)
#--------------------------------------------------------------

data "aws_ami" "amazon_linux_2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

#--------------------------------------------------------------
# IAM Role for NAT Instance (Systems Manager Session Manager)
#--------------------------------------------------------------

resource "aws_iam_role" "nat_instance" {
  name_prefix = "${local.name_prefix}-nat-instance-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-instance-role"
    }
  )
}

# Attach SSM Policy for Session Manager
resource "aws_iam_role_policy_attachment" "nat_instance_ssm" {
  role       = aws_iam_role.nat_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat_instance" {
  name_prefix = "${local.name_prefix}-nat-instance-"
  role        = aws_iam_role.nat_instance.name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-instance-profile"
    }
  )
}

#--------------------------------------------------------------
# Elastic IPs for NAT Instances
#--------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip-${var.availability_zones[count.index]}"
    }
  )

  # Ensure EIP is created after IGW
  depends_on = [aws_internet_gateway.main]
}

#--------------------------------------------------------------
# NAT Instances
#--------------------------------------------------------------

resource "aws_instance" "nat" {
  count = length(var.availability_zones)

  ami                    = data.aws_ami.amazon_linux_2023_arm64.id
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.nat.id]
  iam_instance_profile   = aws_iam_instance_profile.nat_instance.name

  # Disable source/destination check for NAT functionality
  source_dest_check = false

  # User data to configure NAT functionality
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    dnf update -y

    # Enable IP forwarding
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-nat.conf
    sysctl -p /etc/sysctl.d/99-nat.conf

    # Configure iptables for NAT
    iptables -t nat -A POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE

    # Save iptables rules
    dnf install -y iptables-services
    systemctl enable iptables
    service iptables save

    # Install CloudWatch agent (optional, for monitoring)
    dnf install -y amazon-cloudwatch-agent

    # Log completion
    echo "NAT instance setup completed at $(date)" >> /var/log/nat-setup.log
  EOF

  # Enable detailed monitoring
  monitoring = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-${var.availability_zones[count.index]}"
      Type = "NAT"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------
# Associate Elastic IPs to NAT Instances
#--------------------------------------------------------------

resource "aws_eip_association" "nat" {
  count = length(var.availability_zones)

  instance_id   = aws_instance.nat[count.index].id
  allocation_id = aws_eip.nat[count.index].id
}

#--------------------------------------------------------------
# Routes to NAT Instances from Private Subnets
#--------------------------------------------------------------

resource "aws_route" "private_nat" {
  count = length(var.availability_zones)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat[count.index].primary_network_interface_id

  depends_on = [aws_instance.nat]
}
