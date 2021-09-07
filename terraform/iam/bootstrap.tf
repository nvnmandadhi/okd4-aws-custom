resource "aws_iam_instance_profile" "bootstrap" {
  name = "${var.infraID}-bootstrap-profile"

  role = aws_iam_role.bootstrap.name
}

resource "aws_iam_role" "bootstrap" {
  name = "${var.infraID}-bootstrap-role"
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
      "Name" = "${var.infraID}-bootstrap-role"
    },
    {
      "kubernetes.io/cluster/${var.infraID}" = "owned"
    }
  )
}

resource "aws_iam_role_policy" "bootstrap" {
  name = "${var.infraID}-bootstrap-policy"
  role = aws_iam_role.bootstrap.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:AttachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DetachVolume",
      "Resource": "*"
    },
    {
      "Action" : [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::*",
      "Effect": "Allow"
    }
  ]
}
EOF
}