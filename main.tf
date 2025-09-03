provider "aws" {
  region = var.aws_region
}

locals {
  source_bucket = "docs-to-translate-${var.bucket_suffix}"
  target_bucket = "translated-docs-${var.bucket_suffix}"
}

# S3 Buckets
resource "aws_s3_bucket" "source" {
  bucket = local.source_bucket
}

resource "aws_s3_bucket" "target" {
  bucket = local.target_bucket

  lifecycle {
    prevent_destroy = false
  }
}

# S3 Lifecycle: expire objects after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "target_lifecycle" {
  bucket = aws_s3_bucket.target.id

  rule {
    id     = "expire-30-days"
    status = "Enabled"

    filter {}  # applies to all objects

    expiration {
      days = 30
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "translate_lambda_role_${var.bucket_suffix}"

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

# IAM Policy for Lambda to access S3 and Translate
resource "aws_iam_policy" "lambda_policy" {
  name        = "translate_lambda_policy_${var.bucket_suffix}"
  description = "IAM policy for Lambda to use S3 and Translate"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.source.arn,
          "${aws_s3_bucket.source.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.target.arn,
          "${aws_s3_bucket.target.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "translate:TranslateText"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function triggered by S3
resource "aws_lambda_function" "translate_function" {
  function_name = "translate-docs-${var.bucket_suffix}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      TARGET_BUCKET = aws_s3_bucket.target.bucket
    }
  }
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.translate_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
}

# S3 event notification to trigger Lambda on new uploads
resource "aws_s3_bucket_notification" "source_trigger" {
  bucket = aws_s3_bucket.source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.translate_function.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
