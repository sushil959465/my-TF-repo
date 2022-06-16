# VPC

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# Availability Zones

data "aws_availability_zones" "available" {
  state = "available"
}


# Public Subnets

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Public-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Public-2"
  }
}

# Private Subnets

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Private-1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Private-2"
  }
}

# Internet Gateway and it's attachment to VPC

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "My-IGW"
  }
}

# EIPs for the NAT Gateways

resource "aws_eip" "eip_for_nat1" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "eip_for_nat2" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

# Two NAT Gateways for HA, one in both public subnets

resource "aws_nat_gateway" "my_nat1" {
  allocation_id = aws_eip.eip_for_nat1.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "my_nat2" {
  allocation_id = aws_eip.eip_for_nat2.id
  subnet_id     = aws_subnet.public2.id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route Tables

resource "aws_route_table" "for_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "for_private1" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat1.id
  }
}

resource "aws_route_table" "for_private2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat2.id
  }
}

# Route Table Associations

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.for_public.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.for_public.id
}

resource "aws_route_table_association" "private_subnet1_association" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.for_private1.id
}

resource "aws_route_table_association" "private_subnet2_association" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.for_private2.id
}

#

