locals {
  azs = ["a", "b"]
}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.env
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

### public subnets ###
resource "aws_subnet" "public" {
  for_each                = toset(local.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 4, index(local.azs, each.value))
  availability_zone       = "${data.aws_region.this.name}${each.value}"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "${aws_vpc.this.tags.Name}-public-${each.value}"
    tier                     = "public"
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${aws_vpc.this.tags.Name}-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

### private subnets ###
resource "aws_subnet" "private" {
  for_each                = toset(local.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 4, index(local.azs, each.value) + length(aws_subnet.public))
  availability_zone       = "${data.aws_region.this.name}${each.value}"
  map_public_ip_on_launch = false
  tags = {
    Name                              = "${aws_vpc.this.tags.Name}-private-${each.value}"
    tier                              = "private"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_eip" "nat" {
  for_each = toset(local.azs)
  domain   = "vpc"
  tags = {
    Name = "nat-${each.value}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each          = toset(local.azs)
  subnet_id         = aws_subnet.public[each.value].id
  allocation_id     = aws_eip.nat[each.value].id
  connectivity_type = "public"
  tags = {
    Name = aws_subnet.private[each.value].tags.Name
  }
}

resource "aws_route_table" "private" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.this.id
  tags = {
    Name = aws_subnet.private[each.value].tags.Name
  }
}

resource "aws_route" "private" {
  for_each               = toset(local.azs)
  route_table_id         = aws_route_table.private[each.value].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value].id
}

resource "aws_route_table_association" "private" {
  for_each       = toset(local.azs)
  route_table_id = aws_route_table.private[each.value].id
  subnet_id      = aws_subnet.private[each.value].id
}

