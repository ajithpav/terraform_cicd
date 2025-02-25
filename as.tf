# Create a Launch Template for EC2 Instances
resource "aws_launch_template" "my_launch_template" {
  name          = "my-launch-template"
  image_id      = "ami-12345678"      # Replace with your AMI ID
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.subnet_az1.id
    security_groups             = [aws_security_group.instance_sg.id]
  }

  tags = {
    Name = "web-server"
  }
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "my_asg" {
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id] # Use both subnets
  min_size            = 2   # Minimum number of instances
  max_size            = 5   # Maximum number of instances
  desired_capacity    = 2   # Start with 2 instances

  target_group_arns = [aws_lb_target_group.my_target_group.arn]

  # Scale out when CPU usage is high
  scaling_policies = {
    scale_out = aws_autoscaling_policy.scale_out.id
    scale_in  = aws_autoscaling_policy.scale_in.id
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# Auto Scaling Policies (Scale Out and Scale In)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
}

# Security Group for EC2 Instances
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
