# Define the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define the S3 bucket to store the application code
resource "aws_s3_bucket" "application_bucket" {
  bucket = "my-hello-world-app"
  acl  = "private"
}


# Upload the application code to the S3 bucket
resource "aws_s3_bucket_object" "application_code" {
  bucket       = aws_s3_bucket.application_bucket.id
  key          = "application.zip"
  source       = "application.zip"
  content_type = "application/zip"
  etag         = filemd5("application.zip")
}

# Define the IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "my-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach an IAM policy to the Lambda role to grant access to the S3 bucket
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.lambda_role.name
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "index.js"
  output_path = "application.zip"
}

# Define the Lambda function
resource "aws_lambda_function" "my_lambda_function" {
  function_name    = "my-hello-world-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  timeout          = 300
  memory_size      = 128
  source_code_hash = data.archive_file.lambda.output_base64sha256
  filename         = "application.zip" 
}

# Define the API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-hello-world-api"
  description = "API Gateway for my Hello World app"
}

# Define the API Gateway deployment
resource "aws_api_gateway_deployment" "my_api_deployment" {
  depends_on = [aws_lambda_function.my_lambda_function]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name = "dev"
}

# Define the API Gateway resource and method
resource "aws_api_gateway_resource" "my_api_resource" {
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "hello"
  rest_api_id = aws_api_gateway_rest_api.my_api.id
}

resource "aws_api_gateway_method" "my_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.my_api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Define the Lambda integration
resource "aws_api_gateway_integration" "my_api_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.my_api_resource.id
  http_method             = aws_api_gateway_method.my_api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

# Define the API Gateway method response
resource "aws_api_gateway_method_response" "my_api_method_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.my_api_resource.id
  http_method = aws_api_gateway_method.my_api_method.http_method
  status_code = "200"
}