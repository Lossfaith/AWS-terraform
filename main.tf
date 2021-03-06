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

//resource "aws_instance" "node" {
//  ami                    = data.aws_ami.ubuntu.id
//  instance_type          = "t3.micro"
//  subnet_id              = module.vpc.public_subnets[0]
//  iam_instance_profile   = aws_iam_instance_profile.node.id
//  vpc_security_group_ids = [aws_security_group.SerafimSecurityGroup.id]
//  key_name               = aws_key_pair.key.key_name
//  tags                   = map("Name", "Node")
//
//  user_data = templatefile("${path.module}/setup-node.sh", {})
//}

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

#----------------------------------------------
resource "aws_alb" "balancer" {
  name               = "BalancerPublic"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SerafimSecurityGroup.id]
  subnets            = module.vpc.public_subnets
}
#-----------------------------------------------
resource "aws_instance" "master" {
  count                  = var.count_instances
  vpc_security_group_ids = [aws_security_group.SerafimSecurityGroup.id]
  iam_instance_profile   = aws_iam_instance_profile.node.id
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  tags                   = map("Name", "Nginx")
  user_data = templatefile("${path.module}/user_data.sh.tmpl",
    {
      d_name_www = aws_route53_record.www.name
      d_name= aws_route53_record.without_www.name
  })
}
#-----------------------------------------------
resource "aws_lb_target_group" "test" {
  name        = "tf-example-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"
  health_check {
    enabled             = true
    path                = "/index.html"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    port                = 80
    interval            = 10
    protocol            = "HTTP"
  }
}
#-------------------------------------------------
resource "aws_lb_target_group_attachment" "test" {
  count            = var.count_instances
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.master[count.index].id
  port             = 80
}
#--------------------------------------------------
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_alb.balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.test.arn
    type             = "forward"
  }
}
#-----------------------------------------------
output "web_loadbalancer_url" {
  value = aws_alb.balancer.dns_name
}