#!/usr/bin/env python3
"""Invoke the deployed AgentCore runtime and fail (non-zero exit) if it did not return a model answer.

Usage: python invoke_test.py <agent_runtime_arn> ["prompt"]
"""
import json
import sys

import boto3

DEFAULT_PROMPT = "In one sentence, what is Amazon Bedrock AgentCore?"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    arn = sys.argv[1]
    prompt = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_PROMPT
    region = arn.split(":")[3]

    client = boto3.client("bedrock-agentcore", region_name=region)
    resp = client.invoke_agent_runtime(
        agentRuntimeArn=arn,
        qualifier="DEFAULT",
        payload=json.dumps({"prompt": prompt}),
    )

    body = resp["response"].read().decode("utf-8")
    print(f"HTTP {resp['ResponseMetadata']['HTTPStatusCode']}")
    print(body)

    try:
        answer = json.loads(body).get("response", "")
    except json.JSONDecodeError:
        answer = ""

    if not answer.strip():
        print("FAIL: no model answer in response", file=sys.stderr)
        return 1

    print("OK: model answered")
    return 0


if __name__ == "__main__":
    sys.exit(main())
