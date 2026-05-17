# ============================================================
# SECURITY GROUPS
# Son como "reglas de firewall" que controlan qué tráfico
# puede entrar o salir de cada instancia.
# ============================================================

# --- Security Group del FRONT ---
# Permite: HTTP (80) y SSH (22) desde cualquier IP pública
resource "aws_security_group" "sg_front" {
  name        = "spa-sg-front"
  description = "Acceso publico al servidor web"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH desde Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Todo el trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-front"
  }
}

# --- Security Group del BACK ---
# Solo acepta tráfico del Front (en puerto 8080 para el microservicio y 22 para SSH)
resource "aws_security_group" "sg_back" {
  name        = "spa-sg-back"
  description = "Acceso solo desde el Front"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "Microservicio desde Front"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_front.id]
  }

  ingress {
    description     = "SSH desde Front (para administracion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_front.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-back"
  }
}

# --- Security Group del DATA ---
# Solo acepta tráfico del Back (puerto 3306 para MySQL)
resource "aws_security_group" "sg_data" {
  name        = "spa-sg-data"
  description = "Acceso solo desde el Back"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "MySQL desde Back"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_back.id]
  }

  ingress {
    description     = "SSH desde Back (para administracion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_back.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-data"
  }
}
