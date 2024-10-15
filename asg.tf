# Launch configuration for backend ASG
resource "aws_launch_configuration" "backend-launchconfig" {
  name_prefix     = "backend-launchconfig"
  image_id        = "ami-045a8ab02aadf4f88"
  instance_type   = "t2.micro"
  key_name        = "ligne8-key" # may fail
  security_groups = [aws_security_group.sg-backend-instances.id]
  user_data       = var.user_data_backend

  lifecycle {
    create_before_destroy = true
  }
}

# Launch configuration for  frontend ASG
resource "aws_launch_configuration" "frontend-launchconfig" {
  name_prefix     = "frontend-launchconfig"
  image_id        = "ami-045a8ab02aadf4f88"
  instance_type   = "t2.micro"
  key_name        = "ligne8-key" # may fail
  security_groups = [aws_security_group.sg-frontend-instances.id]
  user_data       = var.user_data_frontend

  lifecycle {
    create_before_destroy = true
  }
}