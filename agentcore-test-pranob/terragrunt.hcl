terraform {
  source = "./src"
}

include {
  path = find_in_parent_folders()
}

locals {
  tags = {
    Environment = "development"
    Service     = "agentcore"
    Owner       = "Pranob Nath"
    Managed     = "terraform"
    Description = "Test AgentCore Runtime to validate hosting a Strands agent on Bedrock"
    Cost        = "devops"
    Name        = "agentcore-test-pranob"
  }
}

inputs = {
  stack_name = "agentcore-test-pranob"

  # Cross-region (EU) inference profile already used by the coding-agent workstation
  model_id = "eu.anthropic.claude-sonnet-4-6"

  # Two-phase deploy: leave empty to create only ECR + IAM, then push an image
  # and set this to the pushed tag (see README.md) to create the runtime.
  image_tag = "7e80b92-202610280954"

  tags = local.tags
}
