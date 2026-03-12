output "terraform_state_bucket_name" {
  value       = aws_s3_bucket.tf_state.bucket
  description = "The name of the S3 bucket used for Terraform state storage."
}

output "terraform_state_lock_table_name" {
  value       = aws_dynamodb_table.tf_lock.name
  description = "The name of the DynamoDB table used for Terraform state locking."
}