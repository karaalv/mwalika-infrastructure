# -- EC2 --

# - Access Profile -

resource "aws_iam_role" "ec2_access_role" {
  name = "mwalika-ec2-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  role       = aws_iam_role.ec2_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_policy" {
  role       = aws_iam_role.ec2_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3_readonly_policy" {
  role       = aws_iam_role.ec2_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Instance profile to attach the role to EC2 instances
resource "aws_iam_instance_profile" "ec2_access_instance_profile" {
  name = "mwalika-ec2-access-instance-profile"
  role = aws_iam_role.ec2_access_role.name
}

# -- EC2 Instance --

# Elastic IP
resource "aws_eip" "ec2_elastic_ip" {
  instance = aws_instance.ec2_instance.id

  tags = {
    Name = "mwalika-production-eip"
  }
}

# EC2 Instance Configuration
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0a6f6deb4d4539124" # Ubuntu 22.04 ARM
  instance_type = "t4g.small"

  iam_instance_profile = aws_iam_instance_profile.ec2_access_instance_profile.name

  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id
  ]
  subnet_id = data.aws_vpc.default.default_subnet_id

  # Startup script
  user_data                   = file("${path.module}/config/ec2/setup.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 40 # GB
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Tags
  tags = {
    Name        = "mwalika-production"
    Environment = "production"
    Project     = "mwalika"
    ManagedBy   = "terraform"
  }
}