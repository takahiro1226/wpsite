# NAT Gateway (Managed NAT Service)
# WordPress on AWS Infrastructure

#--------------------------------------------------------------
# Elastic IPs for NAT Gateways
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
# NAT Gateways
#--------------------------------------------------------------

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-gw-${var.availability_zones[count.index]}"
    }
  )

  # Ensure NAT Gateway is created after IGW for proper routing
  depends_on = [aws_internet_gateway.main]
}

#--------------------------------------------------------------
# Routes to NAT Gateways from Private Subnets
#--------------------------------------------------------------

resource "aws_route" "private_nat" {
  count = length(var.availability_zones)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id

  depends_on = [aws_nat_gateway.main]
}
