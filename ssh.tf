resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "key-private" {
  name        = "/private"
  description = "private ssh key"
  type        = "SecureString"
  value       = tls_private_key.key.private_key_pem
}

resource "aws_ssm_parameter" "key-public" {
  name        = "/public"
  description = "public ssh key"
  type        = "SecureString"
  value       = tls_private_key.key.public_key_openssh
}

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = tls_private_key.key.public_key_openssh
}