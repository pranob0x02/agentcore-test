output "ecr_repository_url" {
  description = "ECR repository to push the ARM64 agent image to."
  value       = aws_ecr_repository.agent.repository_url
}

output "runtime_role_arn" {
  description = "Execution role assumed by the AgentCore runtime."
  value       = aws_iam_role.runtime.arn
}

output "agent_runtime_arn" {
  description = "ARN to invoke (null until image_tag is set)."
  value       = one(aws_bedrockagentcore_agent_runtime.agent[*].agent_runtime_arn)
}

output "agent_runtime_id" {
  description = "Runtime ID (null until image_tag is set)."
  value       = one(aws_bedrockagentcore_agent_runtime.agent[*].agent_runtime_id)
}

output "model_id" {
  description = "Model/inference profile the runtime role is allowed to invoke."
  value       = var.model_id
}
