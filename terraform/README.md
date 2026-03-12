# Terraform Infrastructure

This directory contains the Terraform configuration for the Mwalika infrastructure.  
Infrastructure resources are organised into separate Terraform scopes based on the platform they manage.

Each scope has its own Terraform root configuration and state, but they share the same backend infrastructure.

## Structure

The infrastructure is divided into two primary scopes:

```txt
terraform/
├─ aws/
│  ├─ main.tf
│  ├─ backend.tf
│  ├─ providers.tf
│  ├─ variables.tf
│  └─ ...
│
├─ mongodb/
│  ├─ main.tf
│  ├─ backend.tf
│  ├─ providers.tf
│  ├─ variables.tf
│  └─ ...
```

### aws/

Contains Terraform configuration for AWS infrastructure, including resources such as:

- EC2 instances
- ECR repositories
- Route 53 DNS configuration
- CloudFront distributions
- WAF configuration
- other AWS infrastructure components

Terraform commands for AWS infrastructure should be executed from within this directory.

Example:

``` bash
cd terraform/aws
terraform init
terraform plan
terraform apply
```

---

### mongodb/

Contains Terraform configuration for MongoDB Atlas infrastructure, including resources such as:

- MongoDB Atlas projects
- MongoDB clusters
- database access configuration
- IP access lists

Terraform commands for MongoDB infrastructure should be executed from within this directory.

Example:

``` bash
cd terraform/mongodb
terraform init
terraform plan
terraform apply
```

## Terraform State

Both Terraform scopes share the same backend infrastructure:

- S3 bucket: mwalika-terraform-state
- DynamoDB table: mwalika-terraform-lock

However, each scope uses a different state key within the bucket to ensure that state files do not conflict.

Example backend configuration:

AWS scope:

```hcl
terraform {
  backend "s3" {
    bucket         = "mwalika-terraform-state"
    key            = "aws/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "mwalika-terraform-lock"
    encrypt        = true
  }
}
```

MongoDB scope:

```hcl
terraform {
  backend "s3" {
    bucket         = "mwalika-terraform-state"
    key            = "mongodb/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "mwalika-terraform-lock"
    encrypt        = true
  }
}
```

This results in two independent state objects within the same bucket:

```txt
s3://mwalika-terraform-state/aws/terraform.tfstate  
s3://mwalika-terraform-state/mongodb/terraform.tfstate
```

Because the state keys differ, the Terraform configurations do not interfere with each other.

## Locking

Both scopes use the shared DynamoDB table `mwalika-terraform-lock` for Terraform state locking.

This prevents multiple Terraform processes from modifying the same state simultaneously and protects against state corruption during concurrent operations.

## Execution Model

Each directory (`aws/` and `mongodb/`) acts as an independent Terraform root module.

Terraform operations must therefore be run from within the corresponding directory.

Terraform will then:

1. initialise the backend  
2. acquire a lock in the DynamoDB table  
3. read the appropriate state object from S3  
4. plan or apply infrastructure changes  
5. release the lock

## Notes

This structure keeps infrastructure concerns clearly separated while allowing both scopes to reuse the same Terraform backend infrastructure.

The separation also reduces the blast radius of infrastructure changes and keeps state files smaller and easier to manage.
