variable "aws_credential" {
  type    = string
  default = "~/.aws/credentials"
}

variable "az" {
  type    = list(string)
  default = ["af-south-1a", "af-south-1b"]
}

variable "public_cidr" {
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
  type        = list(string)
  description = "Cidr Block for the public subnets"
}

variable "private_cidr" {
  default     = ["10.0.2.0/24", "10.1.3.0/24", "10.1.4.0/24", ]
  type        = list(string)
  description = "Cidr Block for the private subnets"
}

variable "web_cidr" {
  default     = ["10.1.2.0/24", "10.1.3.0/24"]
  type        = list(string)
  description = "cidr block for the web tier subnets"
}

variable "data_cidr" {
  default     = ["10.1.4.0/24", "10.1.5.0/24"]
  type        = list(string)
  description = "cidr block for the data tier subnets"
}
