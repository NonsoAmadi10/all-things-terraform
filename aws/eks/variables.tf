
variable "aws_credential" {
type = string
default = "~/.aws/credentials"
}

variable "az" {
  type = list(string)
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "cluster_name"{
    type = string 
    default = "example"
}

variable "database_name"{
    type = string 
    default = "example"
}



variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::5849380830846405:user/exampleUser1"
      username = "exampleUser1"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::5849380830846405:user/exampleUser2"
      username = "exampleUser2"
      groups   = ["system:masters"]
    },
     {
      userarn  = "arn:aws:iam::5849380830846405:user/exampleUser3"
      username = "exampleUser3"
      groups   = ["system:masters"]
    },
  ]
}


variable "namespace" {
  description = "Default namespace"
  default= "example"
}

variable "redis_cluster_id"{
  type = string 
  default = "example"
}
