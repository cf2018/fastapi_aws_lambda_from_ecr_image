SHELL := /bin/bash

# Load variables from .env if present
ifneq (,$(wildcard .env))
include .env
export
endif

.PHONY: help venv install dev run docker-build docker-run ecr-login ecr-push ecr-delete-image ecr-delete-repo tf-init tf-apply tf-destroy deploy destroy-all clean

AWS_REGION ?= us-east-1
STAGE ?= dev
LAMBDA_NAME ?= fastapi_aws_lambda
ECR_REPO ?= fastapi-aws-lambda
IMAGE_TAG ?= latest
VENV_DIR ?= .venv
ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null)
ECR_URI ?= $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO):$(IMAGE_TAG)

help:
	@echo "Targets: venv, install, dev, run, docker-build, docker-run, ecr-login, ecr-push, ecr-delete-image, ecr-delete-repo, tf-init, tf-apply, tf-destroy, deploy, destroy-all, clean"

venv:
	python -m venv $(VENV_DIR)

install: venv
	$(VENV_DIR)/bin/pip install -r requirements.txt

dev: install
	$(VENV_DIR)/bin/uvicorn app.main:app --reload --port 8000

run: install
	$(VENV_DIR)/bin/uvicorn app.main:app --port 8000



docker-build:
	docker build -t $(ECR_REPO):$(IMAGE_TAG) -f Dockerfile --target lambda .

docker-run:
	docker build -t $(LAMBDA_NAME)-dev:local -f Dockerfile --target dev . && \
	docker run --rm -p 8000:8000 --env-file .env $(LAMBDA_NAME)-dev:local

ecr-login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $$(aws ecr describe-registry --query 'registryId' --output text).dkr.ecr.$(AWS_REGION).amazonaws.com

ecr-push: ecr-login
	aws ecr describe-repositories --repository-names $(ECR_REPO) --region $(AWS_REGION) >/dev/null 2>&1 || \
	  aws ecr create-repository --repository-name $(ECR_REPO) --region $(AWS_REGION)
	docker tag $(ECR_REPO):$(IMAGE_TAG) $(ECR_URI)
	docker push $(ECR_URI)

ecr-delete-image:
	aws ecr batch-delete-image --repository-name $(ECR_REPO) --image-ids imageTag=$(IMAGE_TAG) --region $(AWS_REGION) || true

ecr-delete-repo:
	aws ecr delete-repository --repository-name $(ECR_REPO) --region $(AWS_REGION) --force || true

tf-init:
	cd terraform && terraform init

tf-apply:
	cd terraform && terraform apply -var "aws_region=$(AWS_REGION)" -var "environment=$(STAGE)" -var "lambda_function_name=$(LAMBDA_NAME)" -var "ecr_repo_name=$(ECR_REPO)" -var "image_tag=$(IMAGE_TAG)" -var "lambda_memory=$(LAMBDA_MEMORY)" -var "lambda_timeout=$(LAMBDA_TIMEOUT)" -var "manage_ecr_repo=false"
	cd terraform && terraform output api_endpoint || true

tf-destroy:
	cd terraform && terraform destroy -var "aws_region=$(AWS_REGION)" -var "environment=$(STAGE)" -var "lambda_function_name=$(LAMBDA_NAME)" -var "ecr_repo_name=$(ECR_REPO)" -var "image_tag=$(IMAGE_TAG)" -var "lambda_memory=$(LAMBDA_MEMORY)" -var "lambda_timeout=$(LAMBDA_TIMEOUT)" -var "manage_ecr_repo=false"

deploy: docker-build ecr-push tf-init tf-apply
	@echo "Chosen Lambda configuration:"
	@echo "  Memory: $(LAMBDA_MEMORY) MB"
	@echo "  Timeout: $(LAMBDA_TIMEOUT) seconds"
	@echo "Deploy complete. See API endpoint above."

destroy-all: tf-destroy ecr-delete-image ecr-delete-repo
	@echo "Destroyed infra and ECR artifacts."

clean:
	rm -rf build .terraform terraform/.terraform *.tfstate* terraform/*.tfstate*
