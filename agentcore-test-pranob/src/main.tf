locals {
  runtime_name = replace(var.stack_name, "-", "_")

  # eu.anthropic.claude-... -> anthropic.claude-... (the underlying foundation model)
  foundation_model_id = replace(var.model_id, "/^(eu|us|apac|global)\\./", "")

  create_runtime = var.image_tag != ""
}

##############################################################################
# ECR repository for the agent image (ARM64, pushed manually - see README.md)
##############################################################################

resource "aws_ecr_repository" "agent" {
  name                 = var.stack_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "agent" {
  repository = aws_ecr_repository.agent.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_images_to_keep} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_images_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

##############################################################################
# Runtime execution role (assumed by AgentCore, not by people)
##############################################################################

resource "aws_iam_role" "runtime" {
  name = "${var.stack_name}-runtime-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AgentCoreAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock-agentcore:${var.aws_region}:${var.aws_account_id}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "runtime" {
  name = "agentcore-runtime"
  role = aws_iam_role.runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrPullAgentImage"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.agent.arn
      },
      {
        Sid      = "LogsDescribeGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:*"
      },
      {
        Sid    = "LogsRuntimeGroups"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      },
      {
        Sid      = "CloudWatchMetrics"
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "bedrock-agentcore"
          }
        }
      },
      {
        Sid    = "InvokeApprovedModelOnly"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}:${var.aws_account_id}:inference-profile/${var.model_id}",
          "arn:aws:bedrock:*::foundation-model/${local.foundation_model_id}*"
        ]
      },
      {
        Sid    = "WorkloadAccessTokens"
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:GetWorkloadAccessToken",
          "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
          "bedrock-agentcore:GetWorkloadAccessTokenForUserId"
        ]
        Resource = [
          "arn:aws:bedrock-agentcore:${var.aws_region}:${var.aws_account_id}:workload-identity-directory/default",
          "arn:aws:bedrock-agentcore:${var.aws_region}:${var.aws_account_id}:workload-identity-directory/default/workload-identity/*"
        ]
      }
    ]
  })
}

##############################################################################
# AgentCore Runtime - only created once an image tag has been provided
##############################################################################

resource "aws_bedrockagentcore_agent_runtime" "agent" {
  count = local.create_runtime ? 1 : 0

  agent_runtime_name = local.runtime_name
  description        = "Test agent runtime (${var.stack_name})"
  role_arn           = aws_iam_role.runtime.arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${aws_ecr_repository.agent.repository_url}:${var.image_tag}"
    }
  }

  network_configuration {
    network_mode = var.network_mode
  }

  environment_variables = merge(
    {
      AWS_REGION         = var.aws_region
      AWS_DEFAULT_REGION = var.aws_region
      MODEL_ID           = var.model_id
    },
    var.environment_variables
  )

  depends_on = [aws_iam_role_policy.runtime]
}
