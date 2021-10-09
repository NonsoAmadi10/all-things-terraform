# Create db subnet group 

resource "aws_db_subnet_group" "rds_db" {
  count = length(var.data_cidr)
  name = "rds-main"
  subnet_ids = [aws_subnet.data_tier_subnets[count.index].id]

  tags = {
    "name" = "rds-terraform"
  }
}

# create db instance 

data "external" "rds" {
  program  = [ "cat", "secrets/rds.json"]
}

resource "aws_db_instance" "default" {
  count = length(var.data_cidr)
  allocated_storage =  50 
  engine = "postgresql"
  engine_version = "10.7"
  instance_class = "db.t3.micro"
  name = "mydb"
  username = "xerom"
  max_allocated_storage = 1000
  password = "${data.external.rds.result.password}"
  db_subnet_group_name = aws_db_subnet_group.rds_db[count.index].name
  vpc_security_group_ids = [ aws_security_group.sg-rds.id ]
}