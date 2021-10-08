# Push your key pair to AWS 
resource "aws_key_pair" "ops" {
    key_name = "SRE"
    public_key = file(var.public_key)

    tags = {
      "name" = "terraform"
    }
}

# Create Elastic Network Interface 

resource "aws_network_interface" "web-eni" {
    count = length(var.web_cidr)
    subnet_id = aws_subnet.web_tier_subnets[count.index].id
    private_ips = [ "10.0.2.1", "10.0.3.1" ]
}


# Create EC2 Instance 
resource "aws_instance" "web_server" {
    count = length(var.web_cidr)
    connection {
      private_key = file(var.private_key)
    }
    ami = var.ami-id
    instance_type = "t3.micro"
    key_name = "SRE"
    vpc_security_group_ids = [aws_security_group.allow_http.id]
    instance_initiated_shutdown_behavior = "terminate"
    subnet_id = aws_subnet.web_tier_subnets[count.index].id
    monitoring = true
    ebs_block_device {
      device_name = "ebs-web"
      delete_on_termination = true
      volume_size = 100
    }
    associate_public_ip_address = true
    network_interface {
      network_interface_id = aws_network_interface.web-eni[count.index].id
      device_index = 0
    }
    
  
}

# create AMI from ec2 instance

resource "aws_ami_from_instance" "webserver-ami" {
    source_instance_id = aws_instance.web_server.id 
    name = "webserver-ami"

    tags = {
      "name" = "terraform"
    }
}

# Create a Launch Template

resource "aws_launch_template" "web_server_lt" {
    name = "webserver-lt"
    image_id = aws_ami_from_instance.webserver-ami.id 
    instance_type = "t3.micro"
    key_name = "SRE"

    tags = {
      "name" = "terraform"
    }
  
}

# Create a Placement Group

resource "aws_placement_group" "webserver-placement" {
    name = "webserver-pg"
    strategy = "spread"
  
}

resource "aws_autoscaling_group" "webserver-asg" {
  count = length(var.az)
  name = "webserver-asg"
  min_size = 2 
  max_size = 10
  health_check_grace_period = 100
  health_check_type = "ELB"
  placement_group = aws_placement_group.webserver-placement.id 
  availability_zones = [var.az[count.index]]
  target_group_arns = [aws_lb_target_group.webserver-lbtg.arn]

  launch_template {
    
    id = aws_launch_template.web_server_lt.id
    version = "$Latest"
  }
}

# Create a Loadbalancer Target Group
resource "aws_lb_target_group" "webserver-lbtg" {
  name = "webserver_lb_target_group"
  port = 80 
  protocol = "HTTP"
  vpc_id = aws_vpc.terraform_vpc.id 
  target_type = "instance"

  tags = {
    "name" = "terraformLBTarget"
  }

  health_check {
    
    enabled = true 
    healthy_threshold = 4 
    unhealthy_threshold = 10 
    interval = 10
    path = "/"
    timeout = 5
    port = "80"

  }
}

# Create An Elastic LoadBalancer - Application LoadBalancer

resource "aws_lb" "web-alb" {
    name = "web-alb"
    internal = false 
    load_balancer_type = "application"
    subnets = aws_subnet.public_subnets.*.id 
}