output "api_endpoint" {
  description = "Invoke URL for the HTTP API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "lambda_function_name" {
  value = aws_lambda_function.fastapi_lambda.function_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Lambda image"
  value       = coalesce(try(aws_ecr_repository.app[0].repository_url, null), format("%s.dkr.ecr.%s.amazonaws.com/%s", data.aws_caller_identity.current.account_id, var.aws_region, var.ecr_repo_name))
}
