provider "aws" {
  region = "eu-west-3"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

terraform {
  backend "s3" {
    bucket         = "genarchi"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
  }
}
