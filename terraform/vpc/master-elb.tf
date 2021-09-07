resource "aws_lb" "api_internal" {
  name                             = "${var.infraID}-int"
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet.private.*.id
  internal                         = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      "Name" = "${var.infraID}-int"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )

  timeouts {
    create = "20m"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb" "api_external" {
  name                             = "${var.infraID}-ext"
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet.public.*.id
  internal                         = false
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      "Name" = "${var.infraID}-ext"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )

  timeouts {
    create = "20m"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb_target_group" "api_internal" {
  name     = "${var.infraID}-aint"
  protocol = "TCP"
  port     = 6443
  vpc_id   = aws_vpc.vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.infraID}-aint"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    port                = 6443
    protocol            = "HTTPS"
    path                = "/readyz"
  }
}

resource "aws_lb_target_group" "api_external" {
  name     = "${var.infraID}-aext"
  protocol = "TCP"
  port     = 6443
  vpc_id   = aws_vpc.vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.infraID}-aext"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    port                = 6443
    protocol            = "HTTPS"
    path                = "/readyz"
  }
}

resource "aws_lb_target_group" "services" {
  name     = "${var.infraID}-sint"
  protocol = "TCP"
  port     = 22623
  vpc_id   = aws_vpc.vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.infraID}-sint"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    port                = 22623
    protocol            = "HTTPS"
    path                = "/healthz"
  }
}

resource "aws_lb_listener" "api_internal_api" {
  load_balancer_arn = aws_lb.api_internal.arn
  protocol          = "TCP"
  port              = "6443"

  default_action {
    target_group_arn = aws_lb_target_group.api_internal.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "api_internal_services" {
  load_balancer_arn = aws_lb.api_internal.arn
  protocol          = "TCP"
  port              = "22623"

  default_action {
    target_group_arn = aws_lb_target_group.services.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "api_external_api" {
  load_balancer_arn = aws_lb.api_external.arn
  protocol          = "TCP"
  port              = "6443"

  default_action {
    target_group_arn = aws_lb_target_group.api_external.arn
    type             = "forward"
  }
}
