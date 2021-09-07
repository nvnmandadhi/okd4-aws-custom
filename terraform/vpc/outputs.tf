output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = data.aws_subnet.public.*.id
}

output "private_subnets" {
  value = data.aws_subnet.private.*.id
}

output "az_to_private_subnet_id" {
  value = zipmap(data.aws_subnet.private.*.availability_zone, data.aws_subnet.private.*.id)
}

output "az_to_public_subnet_id" {
  value = zipmap(data.aws_subnet.public.*.availability_zone, data.aws_subnet.public.*.id)
}

output "bootstrap_sg" {
  value = aws_security_group.bootstrap.id
}

output "master_sg" {
  value = aws_security_group.master.id
}

output "worker_sg" {
  value = aws_security_group.worker.id
}

output "aws_lb_target_group_arns" {
  value = compact(
    concat(
      aws_lb_target_group.api_internal.*.arn,
      aws_lb_target_group.services.*.arn,
      aws_lb_target_group.api_external.*.arn,
    )
  )
}

output "aws_lb_api_external_dns_name" {
  value = aws_lb.api_external.dns_name
}

output "aws_lb_api_external_zone_id" {
  value = aws_lb.api_external.zone_id
}

output "aws_lb_api_internal_dns_name" {
  value = aws_lb.api_internal.dns_name
}

output "aws_lb_api_internal_zone_id" {
  value = aws_lb.api_internal.zone_id
}