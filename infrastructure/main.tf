provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MicroservicesVPC"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_security_group" "microservice" {
  name        = "microservice_sg"
  description = "Allow microservice traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "microservice_role" {
  name = "microservice_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_route53_zone" "microservice_dns" {
  name = "microservice.local"
}

resource "aws_iam_instance_profile" "microservice_profile" {
  name = "microservice_profile"
  role = aws_iam_role.microservice_role.name
}

resource "aws_instance" "microservice_instance" {
  ami                    = "ami-0440d3b780d96b29d"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.microservice.id]

  iam_instance_profile = aws_iam_instance_profile.microservice_profile.name

  tags = {
    Name = "MicroserviceInstance"
  }
}

resource "aws_lb" "microservice_alb" {
  name               = "microservice-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.microservice.id]
  subnets            = [aws_subnet_1.public.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "MicroserviceALB"
  }
}

resource "aws_lb_target_group" "microservice_tg" {
  name     = "microservice-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled = true
    path    = "/"
    port    = "traffic-port"
    protocol= "HTTP"
  }
}

resource "aws_lb_listener" "microservice_listener" {
  load_balancer_arn = aws_lb.microservice_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservice_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "microservice_tg_attachment" {
  target_group_arn = aws_lb_target_group.microservice_tg.arn
  target_id        = aws_instance.microservice_instance.id
  port             = 80
}

resource "aws_cloudwatch_log_group" "microservice_log_group" {
  name = "/aws/microservice/logs"

  retention_in_days = 14
}

