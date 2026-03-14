# This file contains the resource for observing
# remote state from other Terraform configurations.
data "terraform_remote_state" "aws" {
  backend = "s3"

  config = {
    bucket  = "mwalika-terraform-state"
    key     = "aws/terraform.tfstate"
    region  = "af-south-1"
    profile = "personal"
  }
}
