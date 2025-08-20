resource "aws_iam_role" "lambda_exec_role" {
  name               = "${var.project_name}-${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_ecr_repository" "app" {
  count                = var.manage_ecr_repo ? 1 : 0
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.tags
}

resource "aws_lambda_function" "fastapi_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  dynamic "image_config" {
    for_each = [1]
    content {
      command = ["handler.handler"]
    }
  }

  package_type = "Image"

  # ECR image-based config
  image_uri = format(
    "%s:%s",
    coalesce(
      try(aws_ecr_repository.app[0].repository_url, null),
      format("%s.dkr.ecr.%s.amazonaws.com/%s", data.aws_caller_identity.current.account_id, var.aws_region, var.ecr_repo_name)
    ),
    var.image_tag
  )

  environment {
    variables = {
      APP_ENV     = var.environment
      STAGE       = var.environment
      LAMBDA_NAME = var.lambda_function_name
    }
  }

  tags = local.tags
}

# API Gateway v2 (HTTP API)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.fastapi_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fastapi_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
