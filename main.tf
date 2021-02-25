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
  subnets            = module.vpc.private_subnets
}