output "alb_url" {
  description = "Public HTTP endpoint for the demo application through the ALB."
  value       = "http://${aws_lb.app.dns_name}"
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 host running kind."
  value       = aws_instance.kind_host.public_ip
}

output "ssh_command" {
  description = "SSH command for debugging the EC2 host."
  value       = "ssh -i ${local_sensitive_file.ssh_private_key.filename} ec2-user@${aws_instance.kind_host.public_ip}"
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Local kubeconfig fetched from the EC2 host after bootstrap."
  value       = "${local.generated_dir}/kubeconfig-${random_id.suffix.hex}-${aws_instance.kind_host.id}.yaml"
}

output "kubeconfig_scp_command" {
  description = "Manual fallback command to fetch kubeconfig if local-exec on Windows fails."
  value       = "scp -o StrictHostKeyChecking=no -i ${local_sensitive_file.ssh_private_key.filename} ec2-user@${aws_instance.kind_host.public_ip}:/home/ec2-user/.kube/config ${local.generated_dir}/kubeconfig-${random_id.suffix.hex}-${aws_instance.kind_host.id}.yaml"
  sensitive   = true
}
