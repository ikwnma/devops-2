# ============================================================
# INSTANCIA FRONT (pública)
# - Nginx como servidor web
# - Docker instalado
# - Git instalado
# - Actualizaciones de seguridad aplicadas
# ============================================================
resource "aws_instance" "front" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  key_name               = "spa-key"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_front.id]

  user_data = <<-EOF
              #!/bin/bash

              # --- Actualizaciones de seguridad ---
              yum update -y --security
              yum update -y

              # --- Servidor web (Nginx) ---
              amazon-linux-extras install nginx1 -y
              systemctl start nginx
              systemctl enable nginx

              # --- Docker ---
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # --- Git ---
              yum install git -y

              # --- Verificacion (los resultados quedan en el log de user_data) ---
              echo "=== VERSION DOCKER ===" >> /var/log/instalaciones.log
              docker --version        >> /var/log/instalaciones.log
              echo "=== VERSION GIT ===" >> /var/log/instalaciones.log
              git --version           >> /var/log/instalaciones.log
              echo "=== ESTADO NGINX ===" >> /var/log/instalaciones.log
              systemctl status nginx  >> /var/log/instalaciones.log
              EOF

  tags = {
    Name = "spa-front"
    Capa = "Front"
  }
}


# ============================================================
# INSTANCIA BACK (privada)
# - Docker instalado
# - JDK (Java) instalado para el microservicio
# - Git instalado
# - Actualizaciones de seguridad aplicadas
# ============================================================
resource "aws_instance" "back" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  key_name               = "spa-key"
  subnet_id              = aws_subnet.private_subnet_back.id
  vpc_security_group_ids = [aws_security_group.sg_back.id]

  user_data = <<-EOF
              #!/bin/bash

              # --- Actualizaciones de seguridad ---
              yum update -y --security
              yum update -y

              # --- Docker ---
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # --- JDK 11 (Java Development Kit para microservicio) ---
              amazon-linux-extras install java-openjdk11 -y

              # --- Git ---
              yum install git -y

              # --- Verificacion ---
              echo "=== VERSION DOCKER ===" >> /var/log/instalaciones.log
              docker --version        >> /var/log/instalaciones.log
              echo "=== VERSION JAVA ===" >> /var/log/instalaciones.log
              java -version           >> /var/log/instalaciones.log 2>&1
              echo "=== VERSION GIT ===" >> /var/log/instalaciones.log
              git --version           >> /var/log/instalaciones.log
              EOF

  tags = {
    Name = "spa-back"
    Capa = "Back"
  }
}


# ============================================================
# INSTANCIA DATA (privada)
# - MySQL instalado (solo instalado, no configurado aún)
# - Git instalado
# - Actualizaciones de seguridad aplicadas
# ============================================================
resource "aws_instance" "data" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  key_name               = "spa-key"
  subnet_id              = aws_subnet.private_subnet_back.id
  vpc_security_group_ids = [aws_security_group.sg_data.id]

  user_data = <<-EOF
              #!/bin/bash

              # --- Actualizaciones de seguridad ---
              yum update -y --security
              yum update -y

              # --- MySQL (motor de base de datos) ---
              # Se instala el servidor MySQL y se inicia el servicio
              yum install mysql-server -y
              systemctl enable mysqld
              systemctl start mysqld

              # --- Git ---
              yum install git -y

              # --- Verificacion ---
              echo "=== VERSION MYSQL ===" >> /var/log/instalaciones.log
              mysql --version         >> /var/log/instalaciones.log
              echo "=== VERSION GIT ===" >> /var/log/instalaciones.log
              git --version           >> /var/log/instalaciones.log
              EOF

  tags = {
    Name = "spa-data"
    Capa = "Data"
  }
}


# ============================================================
# LAUNCH TEMPLATES
# Un Launch Template es una "plantilla de lanzamiento": guarda
# toda la configuración de una instancia para que puedas
# recrearla rápidamente o usarla con Auto Scaling Groups.
# ============================================================

resource "aws_launch_template" "lt_front" {
  name_prefix   = "lt-front-"
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = "spa-key"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_front.id]
    subnet_id                   = aws_subnet.public_subnet.id
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y --security
    yum update -y
    amazon-linux-extras install nginx1 docker -y
    yum install git -y
    systemctl start nginx docker
    systemctl enable nginx docker
    usermod -aG docker ec2-user
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "spa-front-lt"
      Capa = "Front"
    }
  }
}

resource "aws_launch_template" "lt_back" {
  name_prefix   = "lt-back-"
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = "spa-key"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.sg_back.id]
    subnet_id                   = aws_subnet.private_subnet_back.id
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y --security
    yum update -y
    amazon-linux-extras install docker java-openjdk11 -y
    yum install git -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "spa-back-lt"
      Capa = "Back"
    }
  }
}

resource "aws_launch_template" "lt_data" {
  name_prefix   = "lt-data-"
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = "spa-key"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.sg_data.id]
    subnet_id                   = aws_subnet.private_subnet_back.id
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y --security
    yum update -y
    yum install mysql-server git -y
    systemctl enable mysqld
    systemctl start mysqld
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "spa-data-lt"
      Capa = "Data"
    }
  }
}
