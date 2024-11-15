# Security group for ports 80 and 443
resource "aws_security_group" "sg-allow-http-https" {
  name        = "allow-http-https"
  description = "Security group to allow HTTP (port 80) and HTTPS (port 443)"
  vpc_id      = aws_vpc.genarchi_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# Security group for port 3000
resource "aws_security_group" "sg-allow-port-4000" {
  name        = "allow-port-4000"
  description = "Security group to allow port 4000"
  vpc_id      = aws_vpc.genarchi_vpc.id

  ingress {
    from_port   = 4000
    to_port     = 4000
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

# Security group for port 3000
resource "aws_security_group" "sg-allow-port-3000" {
  name        = "allow-port-3000"
  description = "Security group to allow port 3000"
  vpc_id      = aws_vpc.genarchi_vpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_security_group" "sg-allow-8080" {
  name        = "allow-8080"
  description = "Security group to allow port 8080"
  vpc_id      = aws_vpc.genarchi_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
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

# Launch template for backend ASG
resource "aws_launch_template" "backend-launchtemplate" {
  name_prefix   = "backend-launchtemplate"
  image_id      = "ami-045a8ab02aadf4f88"
  instance_type = "t2.micro"
  key_name      = "ligne8-key"

  network_interfaces {
    security_groups = [aws_security_group.allow_ssh.id, aws_security_group.sg-allow-port-4000.id]
  }

  user_data = base64encode(templatefile("./scripts/backend.sh", {}))

  lifecycle {
    create_before_destroy = true
  }
}

# Launch template for frontend ASG
resource "aws_launch_template" "frontend-launchtemplate" {
  name_prefix   = "frontend-launchtemplate"
  image_id      = "ami-045a8ab02aadf4f88"
  instance_type = "t2.micro"
  key_name      = "ligne8-key"

  network_interfaces {
    security_groups = [aws_security_group.allow_ssh.id, aws_security_group.sg-allow-port-3000.id, aws_security_group.sg-allow-http-https.id]
  }

  user_data = base64encode(templatefile("./scripts/frontend.sh", { BACKEND_URL = aws_lb.webapp-alb.dns_name, test="coucou" }))

  lifecycle {
    create_before_destroy = true
  }
}
# ASG Backend
resource "aws_autoscaling_group" "backend-asg" {
  name                      = "backend-asg"
  vpc_zone_identifier       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.backend-launchtemplate.id
    version = "$Latest"
  }
  min_size                  = 1
  desired_capacity          = 2
  max_size                  = 4
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.webapp-back-target-group.arn]
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "backend"
    propagate_at_launch = true
  }
}

# ASG Frontend
resource "aws_autoscaling_group" "frontend-asg" {
  name                      = "frontend-asg"
  vpc_zone_identifier       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_template {
    id      = aws_launch_template.frontend-launchtemplate.id
    version = "$Latest"
  }
  min_size                  = 1
  desired_capacity          = 2
  max_size                  = 4
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.webapp-front-target-group.arn]
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "frontend"
    propagate_at_launch = true
  }
}

# ALB
resource "aws_lb" "webapp-alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.sg-allow-http-https.id, aws_security_group.sg-allow-port-3000.id, aws_security_group.sg-allow-8080.id] 

  tags = {
    Name = "webapp-alb-tf"
  }
}

# ALB listener front
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.webapp-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-front-target-group.arn
  }
}

# ALB listener back
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.webapp-alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-back-target-group.arn
  }
}

# ALB Target front
resource "aws_lb_target_group" "webapp-front-target-group" {
  name     = "webapp-front-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.genarchi_vpc.id
  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 5
    path                = "/"
    matcher             = "200"
  }
}

# ALB Target back
resource "aws_lb_target_group" "webapp-back-target-group" {
  name     = "webapp-back-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.genarchi_vpc.id
  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 5
    path                = "/health"
    matcher             = "200"
  }
}

################################################################


resource "aws_autoscaling_policy" "cpu-policy-scaleup-frontend" {
  name                   = "cpu-policy-scaleup-frontend-asg"
  autoscaling_group_name = "frontend-asg"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1 
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "cpu-policy-scaleup-backend" {
  name                   = "cpu-policy-scaleup-backend-asg"
  autoscaling_group_name = "backend-asg"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1 
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaleup-frontend" {
  alarm_name          = "cpu-alarm-frontend-asg"
  alarm_description   = "cpu-alarm-frontend-asg"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 #seconds 10
  statistic           = "Average"
  threshold           = 50

  dimensions = {
    "AutoScalingGroupName" = "frontend-asg"
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu-policy-scaleup-frontend.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaleup-backend" {
  alarm_name          = "cpu-alarm-backend-asg"
  alarm_description   = "cpu-alarm-backend-asg"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 #seconds 10
  statistic           = "Average"
  threshold           = 50

  dimensions = {
    "AutoScalingGroupName" = "backend-asg"
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu-policy-scaleup-backend.arn]
}


# Scale down alarm
resource "aws_autoscaling_policy" "cpu-policy-scaledown-backend" {
  name                   = "cpu-policy-scaledown-backend-asg"
  autoscaling_group_name = "backend-asg"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = 120
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaledown-backend" {
  alarm_name          = "cpu-alarm-scaledown-backend-asg"
  alarm_description   = "cpu-alarm-scaledown-backend-asg"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 #10
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    "AutoScalingGroupName" = "backend-asg"
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu-policy-scaledown-backend.arn]
}

# Scale down alarm
resource "aws_autoscaling_policy" "cpu-policy-scaledown-frontend" {
  name                   = "cpu-policy-scaledown-frontend-asg"
  autoscaling_group_name = "frontend-asg"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = 120
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaledown-frontend" {
  alarm_name          = "cpu-alarm-scaledown-frontend-asg"
  alarm_description   = "cpu-alarm-scaledown-frontend-asg"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 #10
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    "AutoScalingGroupName" = "frontend-asg"
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu-policy-scaledown-frontend.arn]
}
