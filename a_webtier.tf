resource "aws_lb_target_group" "target_group" {
  name        = "web-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check {
    interval            = 100
    path                = "/"
    timeout             = 50
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb" "webtier_alb" {
  name                       = "web-lb-tf"
  internal                   = false
  ip_address_type            = "ipv4"
  load_balancer_type         = "application"
  security_groups            = [module.webtier_alb_sg.security_group_id["webtier_alb_sg"]]
  subnets                    = [aws_subnet.subnet["subnet_pub_1a"].id, aws_subnet.subnet["subnet_pub_1b"].id]
  enable_deletion_protection = true
  tags = {
    name = "gogreen_ALB"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.webtier_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }
}

# resource "aws_lb_target_group_attachment" "ec2_attach" {
#   count            = length(aws_instance.web-server)
#   target_group_arn = aws_lb_target_group.target_group.arn
#   target_id        = aws_instance.web-server[count.index].id
# }

output "elb-dns-name" {
  value = aws_lb.webtier_alb.dns_name
}