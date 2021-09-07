data "aws_vpc" "cluster_vpc" {
  id = aws_vpc.vpc.id
}

data "aws_subnet" "public" {
  count = length(var.availability_zones)

  id = aws_subnet.public_subnet[count.index].id
}

data "aws_subnet" "private" {
  count = length(var.availability_zones)

  id = aws_subnet.private_subnet[count.index].id
}