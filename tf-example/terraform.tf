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
# set -e

# Install dependencies

apt-get -y -qq update
apt-get -y -qq install curl wget git vim apt-transport-https ca-certificates nginx

# Setup NodeJS 14.x
# curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
apt-get -y -qq install nodejs
apt-get -y -qq install npm
npm install pm2@latest -g

# Setup sudo to allow no-password sudo for "hashicorp" group and adding "terraform" user
#sudo groupadd -r hashicorp
#sudo useradd -m -s /bin/bash terraform
#sudo usermod -a -G hashicorp terraform
#sudo cp /etc/sudoers /etc/sudoers.orig
#echo "terraform ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/terraform

# Change deployment directory path and permissions
sudo mkdir -p /var/app
sudo chown -R ubuntu:ubuntu /var/app

# Setup nginx
# Remove the default configuration
# sudo sh -c '> /etc/nginx/sites-available/default' && \
sudo sh -c 'sudo cat <<EOF > /etc/nginx/sites-enabled/web.conf

upstream app_upstream {
  server 127.0.0.1:3000;
  keepalive 64;
}

server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;

  location / {
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header Host \$http_host;
      
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
      
    proxy_pass http://app_upstream/;
    proxy_redirect off;
    proxy_read_timeout 240s;
  }
}
       EOF
}


resource "aws_security_group" "github-ac-sg" {
  name = "gt-sc-grp"
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

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.github.zone_id
  name    = var.githubb-action
  type    = "A"
  ttl     = 300
  records = [aws_instance.tf-ec2.public_ip]
}
data "aws_route53_zone" "github" {
  name         =var.hosted_zone
}

variable "githubb-action" {
  default     = "github.bayyavuz.com"
}

variable "hosted_zone" {
  default     = "bayyavuz.com"
}

output "tf-ec2" {
  value = aws_instance.tf-ec2.public_ip
}
