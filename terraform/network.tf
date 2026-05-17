# ============================================================
# VPC Y SUBNETS
# Una VPC es nuestra red privada virtual en AWS.
# Dentro tenemos subnets: una pública (Front) y dos privadas (Back y Data).
# ============================================================
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "spa-vpc"
  }
}

# Subnet pública: aquí vive el Front (tiene acceso a Internet)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "spa-subnet-publica"
  }
}

# Subnet privada 1: aquí vive el Back
resource "aws_subnet" "private_subnet_back" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "spa-subnet-privada-back"
  }
}

# Nota: spa-data comparte la subnet privada del Back (10.0.2.0/24)
# El aislamiento entre Back y Data se garantiza mediante Security Groups.


# ============================================================
# INTERNET GATEWAY Y RUTAS
# El Internet Gateway permite que la subnet pública salga a Internet.
# ============================================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "spa-igw"
  }
}

# Tabla de rutas para la subnet pública: el tráfico sale por el IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "spa-rt-publica"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat" {
  tags = {
    Name = "spa-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "spa-nat-gateway"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "spa-rt-privada"
  }
}

resource "aws_route_table_association" "private_back_assoc" {
  subnet_id      = aws_subnet.private_subnet_back.id
  route_table_id = aws_route_table.private_rt.id
}
