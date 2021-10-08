resource "aws_security_group" "allow_http" {
    vpc_id = aws_vpc.terraform_vpc.id 

    ingress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Allow HTTP"
      from_port = 80
      ipv6_cidr_blocks = [ aws_vpc.terraform_vpc.ipv6_cidr_block ]
      prefix_list_ids = [  ]
      protocol = "tcp"
      security_groups = [  ]
      self = false
      to_port = 80
    },
    {
        cidr_blocks = [ "0.0.0.0/0" ]
      description = "Allow HTTPS"
      from_port = 443
      ipv6_cidr_blocks = [ aws_vpc.terraform_vpc.ipv6_cidr_block ]
      prefix_list_ids = [  ]
      protocol = "tcp"
      security_groups = [  ]
      self = false
      to_port = 443
    
    },
    {
        cidr_blocks = [ "0.0.0.0/0" ]
      description = "Allow SSH"
      from_port = 22
      ipv6_cidr_blocks = [ aws_vpc.terraform_vpc.ipv6_cidr_block ]
      prefix_list_ids = [  ]
      protocol = "tcp"
      security_groups = [  ]
      self = false
      to_port = 22
    
    }
     ]

     egress = [ {
       cidr_blocks = [ "0.0.0.0/0" ]
       description = "Allow any Traffic"
       from_port = 0
       ipv6_cidr_blocks = [ aws_vpc.terraform_vpc.ipv6_cidr_block ]
       prefix_list_ids = [ "" ]
       protocol = "-1"
       security_groups = [  ]
       self = false
       to_port = 0
     } ]
  
  tags = {
    "name" = "terraform-sg"
  }
}

resource "aws_security_group" "sg-rds" {
  vpc_id = aws_vpc.terraform_vpc.id 
  count = length(var.web_cidr)
    ingress = [ {
      cidr_blocks = [var.web_cidr[count.index]]
      description = "Allow HTTP"
      from_port = 5432
      ipv6_cidr_blocks = [ aws_vpc.terraform_vpc.ipv6_cidr_block ]
      prefix_list_ids = [  ]
      protocol = "tcp"
      security_groups = [  ]
      self = false
      to_port = 5432
    },
     ]

     egress = [ {
       cidr_blocks = [ "0.0.0.0/0" ]
       description = "Allow any Traffic"
       from_port = 0
       ipv6_cidr_blocks = [ aws_vpc.terraform_vpc.ipv6_cidr_block ]
       prefix_list_ids = [ "" ]
       protocol = "-1"
       security_groups = [  ]
       self = false
       to_port = 0
     } ]
  
  tags = {
    "name" = "terraform-sg"
  }
}