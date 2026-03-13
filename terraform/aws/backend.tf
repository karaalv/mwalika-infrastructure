terraform {
  backend "s3" {
    bucket       = "mwalika-terraform-state"
    key          = "aws/terraform.tfstate"
    region       = "af-south-1"
    profile      = "personal"
    use_lockfile = true
    encrypt      = true
  }
}