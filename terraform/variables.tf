variable "project_name" {
  description = "Project name used for tagging and naming resources"
  type        = string
  default     = "fastapi_aws_lambda"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "fastapi_aws_lambda"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "fastapi-aws-lambda"
}

variable "image_tag" {
  description = "Docker image tag to deploy (e.g., latest, v1.0.0)"
  type        = string
  default     = "latest"
}

variable "lambda_memory" {
  description = "Lambda memory size"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "manage_ecr_repo" {
  description = "Let Terraform create/manage the ECR repository (true) or use an existing repo (false)."
  type        = bool
  default     = true
}
