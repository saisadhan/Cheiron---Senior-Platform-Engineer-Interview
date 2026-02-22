# -------------------------------
# ALB Security Group
# -------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = "vpc-014cbc9d4ed308fa6"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------
# Application Load Balancer
# -------------------------------
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    "subnet-05069cb5c75ae32f9",  # us-west-2c
    "subnet-0d99a3f98f261ac2a"   # us-west-2a
  ]
}

# -------------------------------
# Target Groups
# -------------------------------
resource "aws_lb_target_group" "tg_service1" {
  name     = "tg-service1"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = "vpc-014cbc9d4ed308fa6"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "tg_service2" {
  name     = "tg-service2"
  port     = 5001
  protocol = "HTTP"
  vpc_id   = "vpc-014cbc9d4ed308fa6"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# -------------------------------
# Attach EC2 Instances to Target Groups
# -------------------------------
resource "aws_lb_target_group_attachment" "service1_attach1" {
  target_group_arn = aws_lb_target_group.tg_service1.arn
  target_id        = aws_instance.service_instances[0].id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "service2_attach1" {
  target_group_arn = aws_lb_target_group.tg_service2.arn
  target_id        = aws_instance.service_instances[0].id
  port             = 5001
}

resource "aws_lb_target_group_attachment" "service1_attach2" {
  target_group_arn = aws_lb_target_group.tg_service1.arn
  target_id        = aws_instance.service_instances[1].id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "service2_attach2" {
  target_group_arn = aws_lb_target_group.tg_service2.arn
  target_id        = aws_instance.service_instances[1].id
  port             = 5001
}

# -------------------------------
# ALB Listener
# -------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = 404
    }
  }
}

# -------------------------------
# ALB Listener Rules (Path-based routing)
# -------------------------------
resource "aws_lb_listener_rule" "service1_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_service1.arn
  }

  condition {
    path_pattern {
      values = ["/service1*"]
    }
  }
}

resource "aws_lb_listener_rule" "service2_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_service2.arn
  }

  condition {
    path_pattern {
      values = ["/service2*"]
    }
  }
}