import os

from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent
from strands.models import BedrockModel

app = BedrockAgentCoreApp()

# Both are required; a missing value should fail loudly instead of falling back to a default model.
MODEL_ID = os.environ["MODEL_ID"]
REGION = os.environ["AWS_REGION"]


@app.entrypoint
def invoke(payload=None):
    prompt = (payload or {}).get("prompt", "Hello, who are you?")

    agent = Agent(
        model=BedrockModel(model_id=MODEL_ID, region_name=REGION),
        system_prompt="You are a helpful assistant. Answer clearly and concisely.",
        name="AgentCoreTest",
    )
    result = agent(prompt)

    # Exceptions are deliberately not caught so a failed model call shows up as a failed invocation.
    return {"model_id": MODEL_ID, "response": str(result)}


if __name__ == "__main__":
    app.run()
