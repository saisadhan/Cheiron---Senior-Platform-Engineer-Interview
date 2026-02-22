# -------------------------------
# Data source: Latest Ubuntu AMI
# -------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical Ubuntu
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-*-amd64-server-*"]
  }
}

# -------------------------------
# Security Group
# -------------------------------
resource "aws_security_group" "service_sg" {
  name        = "service-sg"
  description = "Allow SSH and ALB traffic"
  vpc_id      = "vpc-014cbc9d4ed308fa6"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["70.176.205.8/32"]
  }

  ingress {
    description     = "HTTP from ALB - service1"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTP from ALB - service2"
    from_port       = 5001
    to_port         = 5001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------
# IAM Role for EC2 to access ECR
# -------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "ec2-ecr-profile"
  role = aws_iam_role.ec2_role.name
}

# -------------------------------
# EC2 Instances
# -------------------------------
resource "aws_instance" "service_instances" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "MyTerraformKey"
  vpc_security_group_ids = [aws_security_group.service_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_role_profile.name

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update system and install Docker, curl, AWS CLI
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y docker.io curl awscli

              # Install Docker Compose v2
              DOCKER_COMPOSE_VERSION=2.23.0
              curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # Start and enable Docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # Create app directory
              APP_DIR=/home/ubuntu/app
              mkdir -p $APP_DIR
              chown -R ubuntu:ubuntu $APP_DIR

              # Login to ECR
              aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 241789449863.dkr.ecr.us-west-2.amazonaws.com

              # Write docker-compose.yml
              cat > $APP_DIR/docker-compose.yml <<EOT
version: '3'
services:
  service1:
    image: 241789449863.dkr.ecr.us-west-2.amazonaws.com/service1:latest
    ports:
      - "5000:5000"
    restart: always

  service2:
    image: 241789449863.dkr.ecr.us-west-2.amazonaws.com/service2:latest
    ports:
      - "5001:5001"
    restart: always
EOT

              # Pull images and run services
              cd $APP_DIR
              docker-compose pull
              docker-compose up -d
              EOF

  tags = {
    Name = "ServiceInstance-${count.index + 1}"
  }
}