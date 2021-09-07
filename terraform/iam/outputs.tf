output "master_instance_profile" {
  value = aws_iam_instance_profile.master.id
}

output "bootstrap_instance_profile" {
  value = aws_iam_instance_profile.bootstrap.id
}

output "worker_instance_profile" {
  value = aws_iam_instance_profile.worker.id
}