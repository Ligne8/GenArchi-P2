# VPC for the cluster
resource "aws_vpc" "genarchi_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    project = "genarchi"
    Name    = "genarchi_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "genarchi_igw" {
  vpc_id = aws_vpc.genarchi_vpc.id
  tags = {
    project = "genarchi"
    Name    = "genarchi-igw"
  }
}

# Public subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.genarchi_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  map_public_ip_on_launch = true
  tags = {
    project = "genarchi"
    Name    = "genarchi-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.genarchi_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3b"
  map_public_ip_on_launch = true
  tags = {
    project = "genarchi"
    Name    = "genarchi-public-subnet-2"
  }
}

# Private subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.genarchi_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    project = "genarchi"
    Name    = "genarchi-private-subnet-1"
  }
}


resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.genarchi_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-3b"
  tags = {
    project = "genarchi"
    Name    = "genarchi-private-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.genarchi_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-3c"
  tags = {
    project = "genarchi"
    Name    = "genarchi-private-subnet-3"
  }
}

# Route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.genarchi_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.genarchi_igw.id
  }
  tags = {
    project = "genarchi"
    Name    = "genarchi-public-rt"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway for Private Subnets
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    project = "genarchi"
    Name    = "genarchi-nat-gw-1"
  }
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id
  tags = {
    project = "genarchi"
    Name    = "genarchi-nat-gw-2"
  }
}

# Route table for private subnets
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.genarchi_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }
  tags = {
    project = "genarchi"
    Name    = "genarchi-private-rt-1"
  }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.genarchi_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }
  tags = {
    project = "genarchi"
    Name    = "genarchi-private-rt-2"
  }
}

# Associate route table with private subnets
resource "aws_route_table_association" "private_rt_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_rt_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}

resource "aws_route_table_association" "private_rt_assoc_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_rt_2.id
}