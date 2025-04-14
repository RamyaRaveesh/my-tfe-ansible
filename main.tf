provider "aws" {
  region = "eu-north-1"  # Choose the region you're working in
}
resource "aws_instance" "my_server" {
  ami = "ami-09bf0117c5b84b0f7"  # Amazon Linux 2023, eu-north-1
  instance_type = "t3.micro"
  key_name      = "my-sample-app"  # Replace with your EC2 key pair
  security_groups = [aws_security_group.web_sg.name]

  tags = {
    Name = "MyServer"
  }
}
resource "aws_security_group" "my_sg" {
  name_prefix = "my_sg_"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows SSH from anywhere (you can restrict if needed)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}
