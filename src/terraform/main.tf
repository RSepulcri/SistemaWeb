provider "aws" {
  region = "us-east-1"  # Altere para a região que você deseja usar
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "api_gateway"
}

resource "aws_lambda_function" "lambda_services" {
  function_name = "lambda_services"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "lambda_services.zip"  # Referência ao código do Lambda que deve ser empacotado
}

resource "aws_elb" "elb" {
  name               = "my-elb"
  availability_zones = ["us-east-1a"]  # Ajuste para suas zonas de disponibilidade
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }
}

resource "aws_rds_instance" "db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password"  # Modifique para algo seguro
  skip_final_snapshot  = true
}

resource "aws_s3_bucket" "bucket" {
  bucket = "my-app-bucket"
}

resource "aws_sqs_queue" "queue" {
  name = "my-sqs-queue"
}

resource "aws_eventbridge_rule" "eventbridge_rule" {
  name        = "my_event_rule"
  event_pattern = jsonencode({
    "source" = ["aws.events"]
  })
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [{
      "Action" = "sts:AssumeRole"
      "Principal" = {
        "Service" = "lambda.amazonaws.com"
      }
      "Effect" = "Allow"
      "Sid" = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_rest_api.api_gateway.root_resource_id
  http_method = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.lambda_services.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}

