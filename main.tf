provider "aws" {
  region = "eu-north-1"  # Choose the region you're working in
}

data "aws_ssm_parameter" "latest_amazon_linux_2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ssm_parameter.latest_amazon_linux_2_ami.value
  instance_type = "t3.micro"
  key_name      = "my-sample-app"  # Replace with your EC2 key pair
  security_groups = [aws_security_group.web_sg.name]

  tags = {
    Name = "WebServer"
  }
}


resource "aws_security_group" "web_sg" {
  name_prefix = "web_sg_"

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

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}
