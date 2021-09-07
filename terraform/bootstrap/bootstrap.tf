data "ignition_config" "bootstrap" {
  replace {
    source = "s3://${var.ignition_bucket_id}/bootstrap.ign"
  }
}

resource "aws_instance" "bootstrap_instance" {
  ami                         = var.fedora_coreos_ami
  iam_instance_profile        = var.bootstrap_instance_profile
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = var.public_subnets[0]
  security_groups = [
    var.bootstrap_sg_id,
    var.master_sg_id
  ]
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 120
    iops        = 4000
    volume_type = "io1"
  }
  volume_tags = {
    "Name"                                            = "${var.infraID}-bootstrap-vol"
    join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
  }
  user_data = data.ignition_config.bootstrap.rendered
  tags = {
    Name                                              = "${var.infraID}-bootstrap"
    join("", ["kubernetes.io/cluster/", var.infraID]) = "owned"
  }
}

resource "aws_lb_target_group_attachment" "bootstrap" {
  depends_on = [aws_instance.bootstrap_instance]

  count = 3

  target_group_arn = var.target_group_list[count.index]
  target_id        = aws_instance.bootstrap_instance.private_ip
}