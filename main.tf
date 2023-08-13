terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["/Users/mikolajsemeniuk/Projects/go-lambda/credentials"]
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

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "/Users/mikolajsemeniuk/Projects/go-lambda/bin"
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
