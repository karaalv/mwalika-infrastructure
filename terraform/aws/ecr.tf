# -- ECR --

variable "services" {
  type    = list(string)
  default = ["mwalika-agent", "mwalika-frontend"]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(var.services)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = each.value
    Project   = "mwalika"
    ManagedBy = "terraform"
  }
}

# Only keep the last 10 images in the repository
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}