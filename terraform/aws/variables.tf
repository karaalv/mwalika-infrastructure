variable "aws_region" {
  description = "The primary AWS region for resource deployment."
  default     = "af-south-1"
  type        = string
}

variable "aws_profile" {
  description = "The profile used to access AWS resources."
  default     = "personal"
  type        = string
}
