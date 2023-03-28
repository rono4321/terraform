Here's an updated Terraform code that creates a Python Lambda function with its IAM roles and policies and also the EventBridge to trigger the Lambda on each new EC2 instance creation. The Lambda function is read from the same directory in a `.tmpl` file and a zip is created using Terraform. 

Here's a sample Python Lambda function:

```python
import json

def handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))
```

The filename of the Python Lambda function should be `main.py`. Here's the overall approach:

1. Create an IAM role for the Lambda function.
2. Create an IAM policy for the Lambda function.
3. Attach the IAM policy to the IAM role.
4. Create a CloudWatch Event Rule to trigger the Lambda function on each new EC2 instance creation.
5. Create a CloudWatch Event Target to specify the Lambda function as the target for the CloudWatch Event Rule.
6. Use Terraform's `archive_file` data source to create a zip file of the Python Lambda function.
7. Use Terraform's `aws_lambda_function` resource to create the Python Lambda function.

Here's the updated Terraform code:

```python
provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
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

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

data "archive_file" "python_lambda_function_zip" {
  type        = "zip"
  source_dir  = "."
  output_path = "./python_lambda_function.zip"
}

resource "aws_lambda_function" "python_lambda_function" {
  filename         = data.archive_file.python_lambda_function_zip.output_path
  function_name    = "python_lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256(data.archive_file.python_lambda_function_zip.output_path)
}

resource "aws_cloudwatch_event_rule" "ec2_instance_creation_rule" {
  name                = "ec2_instance_creation_rule"
  description         = "Event rule for EC2 instance creation."
  event_pattern       = jsonencode({
    source      = ["aws.ec2"]
    detail_type = ["EC2 Instance State-change Notification"]
    detail      = {
      state   = ["running"]
      instance-id   : ["${aws_instance.example.id}"]
    }
  })
}

resource "aws_cloudwatch_event_target" "python_lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_instance_creation_rule.name
  arn       = aws_lambda_function.python_lambda_function.arn
}
```

You can modify the code according to your requirements and replace the values of the variables with your own values. Let me know if you have any questions or if there's anything else I can help you with.
