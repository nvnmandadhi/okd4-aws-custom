locals {
  new_private_cidr_range = cidrsubnet(data.aws_vpc.cluster_vpc.cidr_block, 1, 1)
  new_public_cidr_range  = cidrsubnet(data.aws_vpc.cluster_vpc.cidr_block, 1, 0)
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                              = "${var.infraID}-vpc",
    join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = concat(
    aws_route_table.private_routes.*.id,
    aws_route_table.default.*.id,
  )

  tags = {
    Name                                              = "${var.infraID}-vpc-endpoint",
    join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
  }
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name         = format("%s.compute.internal", var.region)
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name                                              = "${var.infraID}-vpc-dhcp",
    join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}

resource "aws_subnet" "public_subnet" {
  count = length(var.availability_zones)

  cidr_block        = cidrsubnet(local.new_public_cidr_range, 3, count.index)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      "Name" = "${var.infraID}-public-${var.availability_zones[count.index]}"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = "${var.infraID}-igw"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = "${var.infraID}-public"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )
}

resource "aws_main_route_table_association" "main_vpc_routes" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.default.id
}

resource "aws_route" "igw_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.default.id
  gateway_id             = aws_internet_gateway.igw.id

  timeouts {
    create = "20m"
  }
}

resource "aws_route_table_association" "route_net" {
  count = length(var.availability_zones)

  route_table_id = aws_route_table.default.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

resource "aws_eip" "nat_eip" {
  vpc = true
  tags = merge(
    {
      "Name" = "${var.infraID}-eip"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = merge(
    {
      "Name" = "${var.infraID}-nat"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )
}

resource "aws_route_table" "private_routes" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = "${var.infraID}-private-${var.availability_zones[count.index]}"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )
}

resource "aws_route" "to_nat_gw" {
  depends_on = [aws_route_table.private_routes]
  count      = length(var.availability_zones)

  route_table_id         = aws_route_table.private_routes[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id

  timeouts {
    create = "20m"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(local.new_private_cidr_range, 3, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      "Name"                            = "${var.infraID}-private-${var.availability_zones[count.index]}"
      "kubernetes.io/role/internal-elb" = ""
    }
  )
}

resource "aws_route_table_association" "private_routing" {
  count = length(var.availability_zones)

  route_table_id = aws_route_table.private_routes[count.index].id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}