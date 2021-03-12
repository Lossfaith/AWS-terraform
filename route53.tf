data "aws_route53_zone" "external" {
  zone_id      = "Z0965014IOCW3PCTMCIJ"
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "www.${data.aws_route53_zone.external.name}"
  type    = "A"
  ttl     = "300"
  records = ["10.0.0.1"]
}

output "external-www" {
  value = aws_route53_record.www.name
}