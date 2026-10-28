variable "aws_region" {
  description = "AWS region to deploy into (provided by the root terragrunt.hcl)."
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID this stack is allowed to deploy into (provided by the root terragrunt.hcl)."
  type        = string
}

variable "stack_name" {
  description = "Name prefix for all resources. Hyphens are converted to underscores for the runtime name."
  type        = string
}

variable "model_id" {
  description = "Bedrock model or inference profile ID the agent is allowed to invoke (e.g. eu.anthropic.claude-sonnet-4-6)."
  type        = string
}

variable "image_tag" {
  description = "Tag of the ARM64 agent image already pushed to ECR. Leave empty to skip creating the runtime."
  type        = string
  default     = ""
}

variable "network_mode" {
  description = "AgentCore Runtime network mode."
  type        = string
  default     = "PUBLIC"
}

variable "environment_variables" {
  description = "Extra environment variables passed to the agent container."
  type        = map(string)
  default     = {}
}

variable "ecr_images_to_keep" {
  description = "Number of images to retain in the ECR repository."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
