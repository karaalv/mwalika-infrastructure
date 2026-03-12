output "terraform_state_bucket_name" {
  value       = aws_s3_bucket.tf_state.bucket
  description = "The name of the S3 bucket used for Terraform state storage."
}
