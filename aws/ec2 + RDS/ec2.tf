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

# Assign Elastic IPS to ENIs

resource "aws_eip" "web-eips" {
    count = length(var.web_cidr)
    vpc = true 
    network_interface = aws_network_interface.web-eni[count.index].id
    depends_on = [
      aws_internet_gateway.igw
    ]
}


# Create EC2 Instance 
resource "aws_instance" "web_server" {
    count = length(var.web_cidr)
    connection {
      private_key = file(var.private_key)
      user = var.default_user
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
    count = length(var.web_cidr)
    source_instance_id = aws_instance.web_server[count.index].id 
    name = "webserver-ami"

    tags = {
      "name" = "terraform"
    }
}

# Create a Launch Template

resource "aws_launch_template" "web_server_lt" {
     count = length(var.web_cidr)
    name = "webserver-lt"
    image_id = aws_ami_from_instance.webserver-ami[count.index].id 
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

# Create an Autoscaling group

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
    
    id = aws_launch_template.web_server_lt[count.index].id
    version = "$Latest"
  }
}

# Create AutoScaling Policy 

resource "aws_autoscaling_policy" "webserver-asp" {
     count = length(var.web_cidr)
    name = "webserver-asp"
    scaling_adjustment = 4
    adjustment_type = "ChangeInCapacity"
    cooldown = 400 
    autoscaling_group_name = aws_autoscaling_group.webserver-asg[count.index].name 
}

# Create a Loadbalancer Target Group
resource "aws_lb_target_group" "webserver-lbtg" {
  name = "webserver-lb-target-group"
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

    tags = {
      "name" = "terraformALB"
    }
}

# Create Application LoadBalancer Listener 

resource "aws_lb_listener" "web-alb-listener" {
  
  load_balancer_arn = aws_lb.web-alb.arn 
  port = "80"
  protocol = "HTTP"

  default_action {
    
    type = "forward"
    target_group_arn = aws_lb_target_group.webserver-lbtg.arn 

  }

}

# Terminate the created ec2 instance after AMI has been baked

resource "null_resource" "postexecution" {
  
     count = length(var.web_cidr)
    depends_on = [
      aws_ami_from_instance.webserver-ami
    ]

    connection {
      host = aws_instance.web_server[count.index].public_ip
      user = var.default_user
      #key_name = file(var.private_key)
    }

    provisioner "remote-exec" {
    inline = [
      "sudo init 0"
    ]
  }

}

# CloudWatch Alarm if CPU Usage hits a 70% threshold

resource "aws_cloudwatch_metric_alarm" "webserver-health" {
   count = length(var.web_cidr)
  alarm_name = "ASGCpuUsage"
  depends_on = [
    aws_autoscaling_group.webserver-asg
  ]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

    dimensions = {
      AutoScalingGroupName = aws_autoscaling_group.webserver-asg[0].name
    }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions = [ aws_autoscaling_group.webserver-asg[count.index].arn ]
}