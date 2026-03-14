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

# AMI lookup
data "aws_ami" "ubuntu_arm" {
	most_recent = true

	owners = ["099720109477"] # Canonical

	filter {
		name   = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
	}

	filter {
		name   = "architecture"
		values = ["arm64"]
	}

	filter {
		name   = "virtualization-type"
		values = ["hvm"]
	}

	filter {
		name   = "root-device-type"
		values = ["ebs"]
	}
}

# EC2 Instance Configuration
resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.ubuntu_arm.id # Ubuntu ARM
  instance_type = "t4g.small"

  iam_instance_profile = aws_iam_instance_profile.ec2_access_instance_profile.name

  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id
  ]
  # Use the first subnet in the default VPC for the EC2 instance
  subnet_id = data.aws_subnets.default_vpc_subnets.ids[0]

  # Startup script
  user_data                   = file("${path.module}/config/ec2/setup.sh")
  user_data_replace_on_change = false

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

  lifecycle {
    ignore_changes = [ami]
  }
}