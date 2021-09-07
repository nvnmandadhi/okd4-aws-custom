resource "aws_iam_instance_profile" "worker" {
  name = "${var.infraID}-worker-profile"

  role = aws_iam_role.worker_role.name
}

resource "aws_iam_role" "worker_role" {
  name = "${var.infraID}-worker-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.${data.aws_partition.current.dns_suffix}"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = merge(
    {
      "Name" = "${var.infraID}-worker-role"
    },
    {
      "kubernetes.io/cluster/${var.infraID}" = "owned"
    }
  )
}

resource "aws_iam_role_policy" "worker_policy" {
  name = "${var.infraID}-worker-policy"
  role = aws_iam_role.worker_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}