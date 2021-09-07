data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

resource "aws_vpc_endpoint" "private_ec2" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = data.aws_vpc_endpoint_service.ec2.service_name
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.private_ec2_api.id
  ]

  subnet_ids = aws_subnet.private_subnet.*.id
  tags = merge(
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    },
    tomap({
      "Name" = "${var.infraID}-ec2-vpce"
    })
  )
}

resource "aws_security_group" "private_ec2_api" {
  name   = "${var.infraID}-ec2-api"
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    },
    tomap({
      "Name" = "${var.infraID}-private-ec2-api",
    })
  )
}

resource "aws_security_group_rule" "private_ec2_ingress" {
  type = "ingress"

  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = aws_vpc.vpc.*.cidr_block

  security_group_id = aws_security_group.private_ec2_api.id
}

resource "aws_security_group_rule" "private_ec2_api_egress" {
  type = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id = aws_security_group.private_ec2_api.id
}