# -- S3 --

# Scripts bucket used for CI/CD pipelines and
# other automation tasks.
resource "aws_s3_bucket" "scripts" {
  bucket = "mwalika-scripts"

  tags = {
    Name        = "mwalika-scripts"
    Environment = "global"
  }
}

resource "aws_s3_bucket_versioning" "scripts_versioning" {
  bucket = aws_s3_bucket.scripts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "scripts_ownership" {
  bucket = aws_s3_bucket.scripts.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "scripts_public_access_block" {
  bucket = aws_s3_bucket.scripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts_encryption" {
  bucket = aws_s3_bucket.scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
