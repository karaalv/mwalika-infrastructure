# -- CodeBuild --

# IAM role for CodeBuild to allow it to interact 
# with other AWS services
resource "aws_iam_role" "codebuild_service_role" {
  name = "mwalika-codebuild-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_permission" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "codebuild_secrets_permission" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch_permission" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_s3_permission" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# CodeBuild project for building ARM Docker images for services.
resource "aws_codebuild_project" "arm_docker_build" {
  name         = "mwalika-arm-docker-build"
  service_role = aws_iam_role.codebuild_service_role.arn

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/config/codebuild/buildspec.yml")
  }

  environment {
    type                        = "ARM_CONTAINER"         # ARM compute environment
    compute_type                = "BUILD_GENERAL1_MEDIUM" # 7 GB RAM, 4 vCPU
    image                       = "aws/codebuild/amazonlinux2-aarch64-standard:2.0"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = "/aws/codebuild/mwalika-arm-docker-build"
      stream_name = "mwalika-arm-docker-build"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  tags = {
    Name      = "mwalika-arm-docker-build"
    Project   = "mwalika"
    ManagedBy = "terraform"
  }
}
