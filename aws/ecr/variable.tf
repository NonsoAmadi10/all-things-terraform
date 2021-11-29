variable "aws_credential" {
type = string
default = "~/.aws/credentials"
}

variable "az" {
  type = list(string)
  default = ["eu-west-1a", "eu-west-1b"]
}