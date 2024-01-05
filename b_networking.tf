# Networking
#################################################
# Key(1)
resource "aws_key_pair" "key" {
  key_name   = "${var.prefix}-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# VPC(1)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# Subnets(6): subnet_pub_1a, subnet_pub_1b, subnet_pvt_2a, subnet_pvt_2a, subnet_pvt_3a, subnet_pvt_3b
resource "aws_subnet" "subnet" {
  for_each                = var.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = join("-", [var.prefix, each.key])
  }
}

#IGW(1)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-igw"
  }
}

#EIP public_a (1)
resource "aws_eip" "eip_a" {
  domain = "vpc"
}

#EIP public_b (1)
resource "aws_eip" "eip_b" {
  domain = "vpc"
}

#NAT Gateway subnet_public_1a
resource "aws_nat_gateway" "gw-pub-1a" {
  allocation_id = aws_eip.eip_a.id
  subnet_id     = aws_subnet.subnet["subnet_pub_1a"].id
}

#NAT Gateway subnet_public_1b
resource "aws_nat_gateway" "gw-pub-1b" {
  allocation_id = aws_eip.eip_b.id
  subnet_id     = aws_subnet.subnet["subnet_pub_1b"].id
}

#Route table(2)Public subnets 1a, 1b
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

#Route table Assosiation(1) Public subnets
resource "aws_route_table_association" "rta_pub_1a" {
  subnet_id      = aws_subnet.subnet["subnet_pub_1a"].id
  route_table_id = aws_route_table.rt_public.id
}
resource "aws_route_table_association" "rta_pub_1b" {
  subnet_id      = aws_subnet.subnet["subnet_pub_1b"].id
  route_table_id = aws_route_table.rt_public.id
}

#Route Table (2) Private subnets 2a, 3a
resource "aws_route_table" "rt_private_2a_3a" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw-pub-1a.id
  }
  tags = {
    Name = "gogreen-private AZone us-west-2a"
  }
}
#Route table Assosiation(1) Private subnets 2a, 3a
resource "aws_route_table_association" "rta_pvt_2a" {
  subnet_id      = aws_subnet.subnet["subnet_pvt_2a"].id
  route_table_id = aws_route_table.rt_private_2a_3a.id
}
resource "aws_route_table_association" "rta_pvt_2b" {
  subnet_id      = aws_subnet.subnet["subnet_pvt_2b"].id
  route_table_id = aws_route_table.rt_private_2a_3a.id
}

#Route Table (2) Private subnets 2b, 3b
resource "aws_route_table" "rt_private_2b_3b" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw-pub-1b.id
  }
  tags = {
    Name = "gogreen-private AZone us-west-2b"
  }
}
#Route table Assosiation(1) Private subnets 2b, 3b
resource "aws_route_table_association" "rta_pvt_3a" {
  subnet_id      = aws_subnet.subnet["subnet_pvt_3a"].id
  route_table_id = aws_route_table.rt_private_2b_3b.id
}
resource "aws_route_table_association" "rta_pvt_3b" {
  subnet_id      = aws_subnet.subnet["subnet_pvt_3b"].id
  route_table_id = aws_route_table.rt_private_2b_3b.id
}





