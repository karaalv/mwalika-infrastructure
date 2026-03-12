# --- Config ---

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.14"
}

provider "aws" {
  region  = var.aws_region
  profile = "personal"
}

# --- Resources ---

# -- S3 State Storage --

# State bucket
resource "aws_s3_bucket" "tf_state" {
  bucket = "mwalika-terraform-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "mwalika-terraform-state"
    Environment = "global"
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "tf_state_ownership" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Server-side encryption for state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_enc" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -- DynamoDB State Locking --

resource "aws_dynamodb_table" "tf_lock" {
  name         = "mwalika-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "mwalika-terraform-lock"
    Environment = "global"
  }
}
