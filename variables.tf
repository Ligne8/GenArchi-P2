# variables.tf

variable "aws_access_key" {
  description = "The AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "The AWS secret key"
  type        = string
}

// ami-045a8ab02aadf4f88
variable "ubuntu-id" {
  description = "The ID of the AMI"
  type        = string
}