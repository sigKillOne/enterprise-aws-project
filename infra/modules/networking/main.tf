# infra/modules/networking/main.tf

# 1. The VPC (Your private slice of the cloud in Mumbai)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" 
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "enterprise-vpc-mumbai"
  }
}

# 2. The Internet Gateway (The gate to the world)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "enterprise-igw"
  }
}

# 3. The Public Subnet (Where our "Front Door" resources live)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a" # Specifically Mumbai Zone A
  map_public_ip_on_launch = true

  tags = {
    Name = "enterprise-public-subnet"
  }
}

# 4. The Elastic IP (A fixed public IP required for the NAT Gateway)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "enterprise-nat-eip"
  }
}

# 5. The NAT Gateway (Sits in the PUBLIC subnet, acts as a one-way mirror for private servers)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "enterprise-nat-gw"
  }

  # Terraform must wait for the Internet Gateway to exist before building the NAT
  depends_on = [aws_internet_gateway.igw]
}

# 6. The Private Subnet (Strictly hidden from the internet)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false # Explicitly false for maximum security

  tags = {
    Name = "enterprise-private-subnet"
  }
}

# 7. Public Route Table & Association (Routes public traffic to the Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # "0.0.0.0/0" means "anywhere on the internet"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "enterprise-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 8. Private Route Table & Association (Routes private outbound traffic to the NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "enterprise-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# 9. Second Public Subnet (Required for the Load Balancer)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1b" # Different zone!
  map_public_ip_on_launch = true

  tags = {
    Name = "enterprise-public-subnet-2"
  }
}

# 10. Route Table Association for the second public subnet
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 11. Second Private Subnet (Required for RDS Database Subnet Group)
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-south-1b" # Different Zone!
  map_public_ip_on_launch = false

  tags = {
    Name = "enterprise-private-subnet-2"
  }
}

# 12. Route Table Association for the second private subnet
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}
