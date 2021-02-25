resource "aws_s3_bucket" "test" {
  bucket_prefix = "artem"

  tags = {
    Name = "Simple"
  }
}