provider "aws" {
  region = "eu-west-1"
  shared_credentials_file = "${var.aws_credential}"
  profile = "default"
}

# create a VPC

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true 
  assign_generated_ipv6_cidr_block = true
  tags = {
    "name" = "terraform"
  }
}

# create an Internet Gateway

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.terraform_vpc.id 
    tags = {
      "name" = "terraform"
    }
  
}

# create a Public Route Table 

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.terraform_vpc.id 
}

# create a Public Route 


resource "aws_route" "public" {
  gateway_id = aws_internet_gateway.igw.id 
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
}

# Create a Private Route Table 

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.terraform_vpc.id 
    count = length(var.private_cidr)
}

# Create a Private Route 

resource "aws_route" "private" {
  count = length(var.web_cidr)
  route_table_id = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.default[count.index].id 
}

# create public subnet 

resource "aws_subnet" "public_subnets" {
    count = length(var.public_cidr)
    vpc_id = aws_vpc.terraform_vpc.id 
    cidr_block = var.public_cidr[count.index]
    availability_zone = var.az[count.index]
    map_public_ip_on_launch = true

    tags = {
      "name" = "terraform"
    }
}

# create private subnets 

resource "aws_subnet" "web_tier_subnets" {
  count = length(var.web_cidr)
  vpc_id = aws_vpc.terraform_vpc.id 
  cidr_block = var.web_cidr[count.index]
  availability_zone = var.az[count.index]

  tags = {
      "name" = "terraform"
  }
}

resource "aws_subnet" "data_tier_subnets" {
  count = length(var.data_cidr)
  vpc_id = aws_vpc.terraform_vpc.id 
  cidr_block = var.data_cidr[count.index]
  availability_zone = var.az[count.index]

  tags = {
    "name" = "terraform"
  }
}

# associate subnets with route tables 

resource "aws_route_table_association" "public_association" {
    count = length(var.public_cidr)
    subnet_id = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "web_tier_asscoiation" {
    count = length(var.web_cidr)
    route_table_id = aws_route_table.private_route_table[count.index].id

    subnet_id = aws_subnet.web_tier_subnets[count.index].id
}

resource "aws_route_table_association" "data_tier_asscoiation" {
    count = length(var.data_cidr)
    route_table_id = aws_route_table.private_route_table[count.index].id

    subnet_id = aws_subnet.data_tier_subnets[count.index].id
}

# NAT resources: This will create 2 NAT gateways in 2 Public Subnets for 2 Web Tier Private Subnets.

resource "aws_eip" "nat" {
  count = length(var.public_cidr)  
  vpc = true

  tags = {
    "name" = "terraform"
  }
}

resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat[count.index].id
  subnet_id = aws_subnet.public_subnets[count.index].id
  count = length(var.public_cidr)

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    "name" = "terraform"
  }
}