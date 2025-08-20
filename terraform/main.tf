provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Optionally reference caller identity for convenience (not directly used here)
data "aws_caller_identity" "current" {}
