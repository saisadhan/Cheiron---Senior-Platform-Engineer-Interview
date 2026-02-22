output "service1_repository_url" {
  description = "ECR URL for Service 1"
  value       = aws_ecr_repository.service1.repository_url
}

output "service2_repository_url" {
  description = "ECR URL for Service 2"
  value       = aws_ecr_repository.service2.repository_url
}

output "instance_public_ips" {
  value = aws_instance.service_instances[*].public_ip
}

output "instance_ids" {
  value = aws_instance.service_instances[*].id
}