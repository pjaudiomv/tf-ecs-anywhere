resource "aws_lb_target_group" "external_target_group" {
  name             = "${var.name}-external"
  port             = 443
  protocol         = "HTTPS"
  target_type      = "ip"
  vpc_id           = local.vpc_id
  protocol_version = "HTTP1"

  health_check {
    enabled  = true
    port     = 443
    protocol = "HTTPS"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - TargetGroup - external"
    }
  )
}


resource "aws_security_group" "alb_external" {
  name   = "${var.name}-alb-SG"
  vpc_id = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - SG - alb_external"
    }
  )
}

resource "aws_security_group_rule" "alb_external_traffic_inbound" {
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_external.id

  from_port = 443
  to_port   = 443

  protocol = "TCP"
  type     = "ingress"
}

resource "aws_security_group_rule" "alb_external_traffic_outbound" {
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_external.id
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  type              = "egress"
}

resource "aws_lb" "lb_external" {
  name               = "${var.name}-external"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_external.id]
  subnets            = local.lb_subnet_ids
  internal           = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - LB - External"
    }
  )
}

resource "aws_lb_listener" "external_listener" {
  certificate_arn   = aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.lb_external.arn
  protocol          = "HTTPS"
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_target_group.arn
  }

  depends_on = [
    aws_lb_target_group.external_target_group
  ]
}

resource "aws_lb_listener" "external_listener_redirect" {
  load_balancer_arn = aws_lb.lb_external.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  depends_on = [
    aws_lb_target_group.external_target_group
  ]
}
