resource "aws_lb" "alb" {
  name                 = "alb"
  internal             = false
  load_balancer_type   = "application"
  security_groups      = [aws_security_group.alb_security_group.id]
  subnets              = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id,
    aws_subnet.public_3.id
  ]
  enable_deletion_protection = false
  tags = {
    Name = "alb"
  }
}

resource "aws_lb_target_group" "target_group_1" {
  name     = "target-group-1"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_1.arn
  }
}

