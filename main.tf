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
#-------------------------------------------------------
provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
    "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}
#----------------------------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "172.16.0.0/16"

  azs            = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]

}
#--------------------------------------------------------
resource "aws_security_group" "SerafimSecurityGroup" {
  name   = "SecurityGroup"
  vpc_id = module.vpc.vpc_id
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
resource "aws_alb" "balancer" {
  name               = "BalancerPublic"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SerafimSecurityGroup.id]
  subnets            = module.vpc.public_subnets
}
#-----------------------------------------------
resource "aws_instance" "master" {
  count = var.count_instances

  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.micro"
  subnet_id       = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  security_groups = [aws_security_group.SerafimSecurityGroup.id]
}
#-----------------------------------------------
resource "aws_lb_target_group" "test" {
  name        = "tf-example-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"
}
resource "aws_lb_target_group_attachment" "test" {
  count            = var.count_instances
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.master[count.index].id
  port             = 80
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_alb.balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}
resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}
#-----------------------------------------------