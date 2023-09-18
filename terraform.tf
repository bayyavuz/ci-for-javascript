terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  access_key = "$(secrets.AWS_ACCESS_KEY_ID)"
  secret_key = "$(secrets.AWS_SECRET_ACCESS_KEY)"
  ## profile = "my-profile"
}

resource "aws_instance" "tf-ec2" {
  ami      = data.aws_ami.ubuntu.id
  key_name = " $(secrets.SSH_PRIVATE_KEY)" 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  tags = {
    "Name" = "created-by-terraform"
  }


data "aws_ami" "ubuntu" {
  executable_users = ["self"]
  most_recent      = true
  name_regex       = "^myami-\\d{3}"
  owners           = ["self"]

  filter {
    name   = "name"
    values = ["myami-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

    user_data = <<-EOF
       #!/bin/bash
       apt-get update -y
       apt-get install nodejs -y
       apt-get install npm
       apt-get remove apache2.* && sudo update-rc.d apache2 remove
       systemctl disable apache2 && sudo systemctl stop apache2
       apt-get install nginx
       EOF
}

resource "aws_security_group" "demo-sg" {
  name = "sec-grp"
  description = "Allow HTTP and SSH traffic via Terraform"

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "tf-ec2" {
  value = aws_instance.control_node.public_ip
}
