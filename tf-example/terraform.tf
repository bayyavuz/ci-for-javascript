terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
      # version = "5.17.0"
    }
  }
  backend "s3" {
    bucket = "github-action-project"
    key = "backend/tf-backend.tfstate"
    region = "us-east-1"
  }
}


provider "aws" {
  region  = "us-east-1"
  # access_key = " AWS_ACCESS_KEY_ID "
  # secret_key = " AWS_SECRET_ACCESS_KEY "
  ## profile = "my-profile"
}

resource "aws_s3_bucket" "example" {
  bucket = "github-action-project"

  tags = {
    Name        = "github-action-project"
    # Environment = "Dev"
  }
}

resource "aws_instance" "tf-ec2" {
  ami = "ami-053b0d53c279acc90"
  # ami      = data.aws_ami.ubuntu.id
  key_name = "first-key" 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.github-ac-sg.id]
  tags = {
    "Name" = "created-by-terraform"
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

resource "aws_security_group" "github-ac-sg" {
  name = "git-scrty-grp"
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
  value = aws_instance.tf-ec2.public_ip
}
