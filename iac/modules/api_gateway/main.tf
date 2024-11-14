resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.api_vars.project_name}-${var.api_vars.environment}-api"
  description = "API Gateway for ${var.api_vars.project_name}"
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = [var.cognito_user_pool_arn]
}

resource "aws_api_gateway_method" "post_auth" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_iam_role" "api_gateway_role" {
  name = "${var.api_vars["project_name"]}-${var.api_vars["environment"]}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_policy" {
  name   = "${var.api_vars["project_name"]}-${var.api_vars["environment"]}-api-gateway-policy"
  role   = aws_iam_role.api_gateway_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:InitiateAuth"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_api_gateway_integration" "cognito" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.auth.id
  http_method             = aws_api_gateway_method.post_auth.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.api_vars["aws_region"]}:cognito-idp:action/InitiateAuth"
	credentials             = aws_iam_role.api_gateway_role.arn
  request_templates = {
    "application/json" = <<EOF
			{
				"AuthParameters" : {
					"USERNAME" : $input.json('$.email'),
					"PASSWORD": $input.json('$.password')
				},
				"AuthFlow" : "USER_PASSWORD_AUTH",
				"ClientId" : "${var.client_admin_id}"
			}
			EOF
  }
}