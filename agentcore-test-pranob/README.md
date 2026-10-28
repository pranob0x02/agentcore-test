# agentcore-test-pranob

Test stack to prove an agent can run on **Amazon Bedrock AgentCore Runtime** in account `****`, using a Bedrock model, with everything managed by Terraform/Terragrunt.

The agent code (`agent/`) is a tiny Strands agent with no integrations. It is **not** the IB-prospecting agent; this only validates the hosting path.

## What it creates

| Resource | Notes |
|---|---|
| ECR repo `agentcore-test-pranob` | Immutable tags, scan on push, keeps last 10 images |
| IAM role `agentcore-test-pranob-runtime-role` | Trusted only by `bedrock-agentcore.amazonaws.com` (this account); can invoke **only** `var.model_id` |
| AgentCore runtime `agentcore_test_pranob` | Created only when `image_tag` is set |


## Deploy (two phases)

The runtime needs an image in ECR before it can be created, so deploy in two steps. Use the SSO profile

**Phase 1 - ECR + IAM**

```bash
cd eu-central-1/agentcore-test-pranob
terragrunt plan
terragrunt apply
```

**Build and push the ARM64 image.** AgentCore only runs ARM64; use a unique tag every time (tags are immutable).

```bash
REPO=$(terragrunt output -raw ecr_repository_url)
TAG=$(git rev-parse --short HEAD)-$(date +%Y%m%d%H%M)

aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin "${REPO%%/*}"
docker buildx build --platform linux/arm64 -t "$REPO:$TAG" --push agent/
echo "$TAG"
```

**Phase 2 - runtime.** Set `image_tag = "<TAG>"` in `terragrunt.hcl`, then:

```bash
terragrunt plan
terragrunt apply
```

## Test

```bash
python agent/invoke_test.py "$(terragrunt output -raw agent_runtime_arn)"
```

Success = HTTP 200 and a model-generated answer (the script exits non-zero otherwise). Check logs in CloudWatch under `/aws/bedrock-agentcore/runtimes/`.

A follow-up `terragrunt plan` should show no changes.

## Redeploying new agent code

Build and push a new unique tag, update `image_tag`, `terragrunt apply`.

## Clean up

Run `terragrunt destroy` (the ECR repo is force-deleted together with its images).

## Notes / follow-ups

- Model access: `model_id` defaults to `eu.anthropic.claude-sonnet-4-6`, already used by the coding-agent workstation. It is a cross-region EU profile; the role allows the profile plus the underlying foundation models in any region.
- `agent/requirements.txt` is not version-pinned (matches the AWS sample). Pin it before using this as a base for a real agent.
- Budget: `eu-central-1/aws-budget/budgets/agentcore-pranob` (USD 50/month). Verify the service names in Cost Explorer after first usage; budgets are alerts, not spending caps.
- `network_mode = "PUBLIC"` for the test. Revisit (VPC mode) before connecting any internal systems.
- No HubSpot/Slack/BI or real lead data should be connected to this stack.
