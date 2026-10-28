FROM public.ecr.aws/docker/library/python:3.11-slim

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

RUN useradd -m -u 1000 bedrock_agentcore
USER bedrock_agentcore

# AgentCore Runtime talks to the container on 8080 (/invocations, /ping)
EXPOSE 8080

COPY agent.py .

CMD ["opentelemetry-instrument", "python", "-m", "agent"]
