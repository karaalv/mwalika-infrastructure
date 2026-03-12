# This file contains locals used as configuration 
# for MongoDB Atlas resources.

locals {
  # Obtains IP address of production EC2
  # instance from AWS remote state
  production_ec2_ip = (
    try(data.terraform_remote_state.aws.outputs.production_ec2_elastic_ip, null)
  )
  # If IP is not available, default to blocking all access
  production_access_cidr = (
    local.production_ec2_ip != null ? "${local.production_ec2_ip}/32" : "0.0.0.0/32"
  )


  # Defines the mapping for MongoDB Atlas projects, 
  # clusters, and IP access based on environments.
  mongodb_environments = {
    development = {
      project_name  = "mwalika-development"
      cluster_name  = "main"
      instance_size = "M0"
      region_name   = "AF_SOUTH_1"
      environment   = "development"
      cidrs         = ["0.0.0.0/0"]
    }

    test = {
      project_name  = "mwalika-test"
      cluster_name  = "main"
      instance_size = "M0"
      region_name   = "AF_SOUTH_1"
      environment   = "test"
      cidrs         = ["0.0.0.0/0"]
    }

    production = {
      project_name  = "mwalika-production"
      cluster_name  = "main"
      instance_size = "M0"
      region_name   = "AF_SOUTH_1"
      environment   = "production"
      cidrs         = [local.production_access_cidr]
    }
  }
}