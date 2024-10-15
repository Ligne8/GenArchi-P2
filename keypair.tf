resource "aws_key_pair" "ligne8" {
  key_name   = "ligne8-key"
  public_key = file("~/.ssh/ssh_keys/ligne8.pub")
}