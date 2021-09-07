resource "aws_security_group" "bootstrap" {
  vpc_id = aws_vpc.vpc.id

  timeouts {
    create = "20m"
  }

  tags = merge(
    {
      "Name" = "${var.infraID}-bootstrap-sg"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.bootstrap.id

  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 22
  to_port     = 22
}

resource "aws_security_group_rule" "bootstrap_journald_gateway" {
  type              = "ingress"
  security_group_id = aws_security_group.bootstrap.id

  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 19531
  to_port     = 19531
}