terraform {
  required_version = "0.14.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.26.0"
    }
  }
  backend "s3" {
    encrypt = false
    bucket  = "terraformtaagerdevtestmaybenotatall"
    region  = "eu-west-1"
    key     = "terraform-test.tfstate"
  }
}

provider "aws" {
  region = var.region
}
data "data_availability_zones" "Zones" {}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}
#--------------------------------------------------------
resource "aws_security_group" "SerafimSecurityGroup" {
  name                  = "SecurityGroup"
  vpc_security_group_id = [aws_security_group.SerafimSecurityGroup.id]
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
#----------------------------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "172.16.0.0/16"

  azs            = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]

}
#----------------------------------------------
resource "aws_alb" "A_Balancer" {
  name               = "Balancer_Public"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SerafimSecurityGroup.id]
  subnets            = module.vpc.public_subnets
}
#-----------------------------------------------
resource "aws_instance" "FirstInstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = module.vpc.public_subnets[0]
  tags = {
    Name = "First"
  }
}
resource "aws_instance" "SecondInstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = module.vpc.public_subnets[1]
  tags = {
    Name = "Second"
  }
}
resource "aws_instance" "ThirdInstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = module.vpc.public_subnets[2]
  tags = {
    Name = "Third"
  }
}
#-----------------------------------------------
