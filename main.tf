provider "aws" {
  region                   = "us-east-1"
  // shared_credentials_files = ["/Users/rahulwagh/.aws/credentials"]
  access_key               = "AKIAVRUVV6GBMWRPUJE6"
  secret_key               = "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"
}
resource "aws_iam_role" "lambda_role1" {
 name   = "terraform_aws_lambda_role1"
 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda

resource "aws_iam_policy" "iam_policy_for_lambda1" {

  name         = "aws_iam_policy_for_terraform_aws_lambda_role1"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role1"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction",
        "s3:*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role1" {
  role        = aws_iam_role.lambda_role1.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda1.arn
}

# Generates an archive from content, a file, or a directory of files.

data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/hello-python.zip"
}

# Create a lambda function
# In terraform ${path.module} is the current directory.
resource "aws_lambda_function" "terraform_lambda_func1" {
 filename                       = "${path.module}/python/hello-python.zip"
 function_name                  = "saho-Lambda-Function1"
 role                           = aws_iam_role.lambda_role1.arn
 handler                        = "hello-python.lambda_handler"
 runtime                        = "python3.8"
 depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role1]


}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = "saho-bucket" # Set a unique name for your bucket
  acl    = "private" # Access Control List for the bucket (private in this example)
  tags = {
    Name        = "MyBucket"
    Environment = "test"
  }
  versioning {
    enabled = true
  }
  }

  resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.my_s3_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.terraform_lambda_func1.arn
    events             = ["s3:ObjectCreated:*"]  # Trigger on any new object creation
    filter_prefix      = "test/"   # Optional: Specify a prefix to filter events for a specific path
  }
}

output "teraform_aws_role_output" {
 value = aws_iam_role.lambda_role1.name
}

output "teraform_aws_role_arn_output" {
 value = aws_iam_role.lambda_role1.arn
}

output "teraform_logging_arn_output" {
 value = aws_iam_policy.iam_policy_for_lambda1.arn
}
resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func1.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.my_s3_bucket.id}"
}