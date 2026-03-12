# This file creates MongoDB Atlas projects based on the
# mapping defined in locals.tf.

resource "mongodbatlas_project" "projects" {
  for_each = local.mongodb_environments

  name   = each.value.project_name
  org_id = var.mongodb_atlas_org_id

  tags = {
    environment = each.value.environment
  }
}