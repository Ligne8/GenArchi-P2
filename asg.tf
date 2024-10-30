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

# Launch configuration for backend ASG
resource "aws_launch_configuration" "backend-launchconfig" {
  name_prefix     = "backend-launchconfig"
  image_id        = "ami-045a8ab02aadf4f88"
  instance_type   = "t2.micro"
  key_name        = "ligne8-key" # may fail
  security_groups = [aws_security_group.allow_ssh.id, aws_security_group.sg-allow-port-3000.id]
  user_data       = templatefile("./scripts/backend.sh", { port = 3000 })

  lifecycle {
    create_before_destroy = false
  }
}

# Launch configuration for  frontend ASG
resource "aws_launch_configuration" "frontend-launchconfig" {
  name_prefix     = "frontend-launchconfig"
  image_id        = "ami-045a8ab02aadf4f88"
  instance_type   = "t2.micro"
  key_name        = "ligne8-key" # may fail
  security_groups = [aws_security_group.allow_ssh.id, aws_security_group.sg-allow-http-https.id]
  user_data       = templatefile("./scripts/frontend.sh", { port = 3000 })

  lifecycle {
    create_before_destroy = true
  }
}

# ASG Backend
resource "aws_autoscaling_group" "backend-autoscaling" {
  name                      = "backend-autoscaling"
  vpc_zone_identifier       = [aws_subnet.private_subnet_1, aws_subnet.private_subnet_2]
  launch_configuration      = aws_launch_configuration.backend-launchconfig.name
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
resource "aws_autoscaling_group" "frontend-autoscaling" {
  name                      = "frontend-autoscaling"
  vpc_zone_identifier       = [aws_subnet.private_subnet_1, aws_subnet.private_subnet_2]
  launch_configuration      = aws_launch_configuration.frontend-launchconfig.name
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
  security_groups    = [aws_security_group.sg-allow-http-https.id, aws_security_group.sg-allow-port-3000.id]

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
  port     = 80
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
  port     = 8080
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
