resource "aws_network_interface" "master" {
  count     = var.master_count
  subnet_id = var.az_to_subnet_id[var.availability_zones[count.index]]

  security_groups = var.master_security_groups

  tags = merge(
    {
      "Name" = "${var.infraID}-master-${count.index}"
    },
    {
      join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
    }
  )
}

data "ignition_config" "master" {
  replace {
    source = "s3://${var.ignition_bucket_id}/master.ign"
  }
}

resource "aws_spot_instance_request" "master" {
  count                = var.master_count
  wait_for_fulfillment = true
  ami                  = var.fedora_coreos_ami
  instance_type        = var.instance_type
  spot_price           = "0.039"
  spot_type            = "one-time"
  ebs_block_device {
    device_name = "/dev/xvda"
    iops        = 4000
    volume_size = 120
    volume_type = "io1"
  }
  volume_tags = {
    "Name"                                            = "${var.infraID}-master-${count.index}-vol"
    join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
  }
  network_interface {
    network_interface_id = aws_network_interface.master[count.index].id
    device_index         = 0
  }
  iam_instance_profile = var.master_instance_profile_name
  user_data            = data.ignition_config.master.rendered
  tags = {
    Name                                              = "${var.infraID}-master-${count.index}"
    join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
  }
}

resource "null_resource" "tag_spot_instances" {
  depends_on = [aws_spot_instance_request.master]
  count      = var.master_count

  provisioner "local-exec" {
    command = <<-EOT
      aws ec2 create-tags --resources ${aws_spot_instance_request.master[count.index].spot_instance_id} --tags Key=Name,Value=${var.infraID}-master-${count.index}
      aws ec2 create-tags --resources ${aws_spot_instance_request.master[count.index].spot_instance_id} --tags Key=${join("", ["kubernetes.io/cluster/", var.infraID])},Value=owned
    EOT
  }
}

resource "aws_lb_target_group_attachment" "master" {
  depends_on = [aws_spot_instance_request.master]

  count = length(aws_spot_instance_request.master.*.id) * var.master_count

  target_group_arn = var.target_group_list[count.index % var.master_count]
  target_id        = aws_spot_instance_request.master[floor(count.index / length(var.target_group_list))].private_ip
}