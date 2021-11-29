provider "aws" {
  region = "eu-west-1"
  shared_credentials_file = "${var.aws_credential}"
  profile = "default"
}