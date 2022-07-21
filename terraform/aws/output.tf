output "activation_code" {
  description = "SSM activation code to register the ECS agent"
  value       = aws_ssm_activation.ssm_activation_pair.activation_code
}

output "ssm_activation_pair" {
  description = "SSM activation pair to register the ECS agent"
  value       = aws_ssm_activation.ssm_activation_pair.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}