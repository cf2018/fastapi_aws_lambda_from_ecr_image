# Multi-stage Dockerfile: Lambda image (for AWS) and dev image (for local run)

#############################
# Stage 1: Lambda runtime image
#############################
FROM public.ecr.aws/lambda/python:3.12 AS lambda

WORKDIR /var/task

# Leverage Docker layer caching
COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt -t .

# Copy application code
COPY app ./app
COPY handler.py ./handler.py

# Lambda entry
CMD ["handler.handler"]

#############################
# Stage 2: Dev image with Uvicorn for local development
#############################
FROM python:3.12-slim AS dev

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY handler.py ./handler.py

EXPOSE 8000

# Start FastAPI for local development
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
