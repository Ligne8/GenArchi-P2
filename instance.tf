resource "aws_instance" "DB-1" {
  ami           = var.ubuntu-id 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_1.id
  key_name      = "ligne8-key"
  private_ip    = "10.0.3.10"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_postgres.id]

  user_data = templatefile("./scripts/db1.sh", {})

  tags = {
    Name = "DB-1-genarchi"
    project = "genarchi"
  }
}

resource "aws_instance" "DB-2" {
  ami           = var.ubuntu-id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_2.id
  private_ip    = "10.0.4.10"
  user_data = templatefile("./scripts/db2.sh", {})
  key_name      = "ligne8-key"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_postgres.id]
  tags = {
    Name = "DB-2-genarchi"
    project = "genarchi"
  }
}


resource "aws_instance" "bastion" {
  ami           = var.ubuntu-id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name      = "ligne8-key"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "bastion-genarchi"
    project = "genarchi"
  }
}

// print bastion ip
output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = aws_vpc.genarchi_vpc.id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.genarchi_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_postgres"
    project = "genarchi"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.genarchi_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
    project = "genarchi"
  }
}