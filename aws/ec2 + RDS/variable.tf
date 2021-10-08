variable "aws_credential" {
type = string
default = "~/.aws/credentials"
}

variable "az" {
  type = list(string)
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "public_cidr" {
    default = [ "10.0.0.0/24", "10.0.1.0/24"]
    type = list(string) 
    description = "Cidr Block for the public subnets"
}

variable "private_cidr" {
    default = [ "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
    type = list(string) 
    description = "Cidr Block for the private subnets"
}

variable "web_cidr" {
    default = ["10.0.2.0/24", "10.0.3.0/24"]
    type = list(string)
    description = "cidr block for the web tier subnets"
}

variable "data_cidr" {
    default = ["10.0.4.0/24", "10.0.5.0/24"]
    type = list(string)
    description = "cidr block for the data tier subnets"
}


variable "public_key" {
    type = string
    default = "~/.ssh/id_rsa.pub"
}

variable "ami-id" {
  default = "ami-05cd35b907b4ffe77"
  type = string
}

variable "private_key"{
    type= string 
    default = "~/.ssh/id_rsa"
}