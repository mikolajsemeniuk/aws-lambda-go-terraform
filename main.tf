terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# 

provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["./credentials"]
  profile                  = "default"
}

resource "aws_iam_role" "lambda_role" {
  name = "aws_go_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/aws_go_lambda" # Typically, Lambda logs follow this naming convention
  retention_in_days = 7
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# resource "aws_iam_role_policy" "lambda_cloudwatch_policy" {
#   name = "LambdaCloudWatchPolicy"
#   role = aws_iam_role.lambda_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Effect   = "Allow",
#         Resource = "arn:aws:logs:*:*:*"
#       }
#     ]
#   })
# }

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "./bin"
  output_path = "main.zip"
}

resource "aws_lambda_function" "example_lambda" {
  filename         = data.archive_file.lambda_function.output_path
  function_name    = "aws_go_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main"
  runtime          = "go1.x"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  environment {
    variables = {
      environment = "development"
    }
  }
}
