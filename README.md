# FastAPI on AWS Lambda (Terraform + ECR Image)

A simple, extensible FastAPI scaffold designed for AWS Lambda behind API Gatewayc,deployed as a container image in ECR. Terraform manages the infra, Mangum adapts ASGI to Lambda.

## Features
- Service/Repository project layout
- AWS Lambda + API Gateway (HTTP API) via Terraform
- ECR container image support (bypass Lambda ZIP size limits, include native libs)
- Mangum to bridge ASGI to Lambda
- .env config via pydantic-settings + python-dotenv
- Easy to extend (add SQS, DB, multiple Lambdas)

## Project Structure
```
app/
  api/
    routes.py
  services/
    hello_service.py
  repositories/
    stub_repo.py
  dependencies/
  core/
    config.py
  main.py
handler.py
requirements.txt
.env
Dockerfile
.dockerignore
scripts/
terraform/
  main.tf
  variables.tf
  outputs.tf
  lambda.tf
```

## Quickstart (one command deploy)

Prereqs: AWS CLI configured, Terraform >= 1.6, Docker. Set your `.env` values to drive the deploy (fallback defaults are provided):

```
# .env
AWS_REGION=us-east-1
STAGE=dev
LAMBDA_NAME=fastapi_aws_lambda
ECR_REPO=fastapi-aws-lambda
IMAGE_TAG=latest
```

Deploy (builds the image, pushes to ECR, applies Terraform):

```
make deploy
```

Manual override (optional):

```
make deploy AWS_REGION=us-east-1 STAGE=dev LAMBDA_NAME=my-func ECR_REPO=my-repo IMAGE_TAG=v1
```

The `api_endpoint` will be printed. Test it:

```
curl "$API_ENDPOINT/"
```

## Local development

Use a local virtual environment (recommended):

```
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Or via Makefile (auto-creates .venv and installs):

```
make dev
```

Or with Docker (uses the `dev` stage):

```
make docker-run
```

Visit http://localhost:8000/ and http://localhost:8000/docs

## Teardown: destroy infra and ECR image/repo

One command (uses `.env`):

```
make destroy-all
```

Manual override:

```
make destroy-all AWS_REGION=us-east-1 STAGE=dev LAMBDA_NAME=my-func ECR_REPO=my-repo IMAGE_TAG=v1
```

<!-- ZIP-based deployment removed; this project deploys Lambda from an ECR image only. -->

## Extensibility
- Add new endpoints under `app/api`
- Add services under `app/services` and repositories under `app/repositories`
- Add new Lambda handlers by creating more entrypoints like `handler.py` and updating Terraform
- Introduce SQS, DynamoDB, or other AWS services in Terraform, then wire repos/services

## Environment
`.env` controls runtime defaults; Terraform also passes the key ones into Lambda.

```

APP_ENV=dev
STAGE=dev
AWS_REGION=us-east-1
LAMBDA_NAME=fastapi_aws_lambda

```

## Notes
- Lambda runtime is Python 3.12 for both the base image. Keep native wheels compatible.
- Minimal dependencies purposely kept small
- Swap to Poetry easily by adding `pyproject.toml`
