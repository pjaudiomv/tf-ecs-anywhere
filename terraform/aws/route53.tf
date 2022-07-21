resource "aws_acm_certificate" "external" {
  domain_name       = "${var.name}.patrickj.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "external_validation" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}

resource "aws_route53_record" "external" {
  zone_id = data.aws_route53_zone.external.id
  name    = "${var.name}.patrickj.org"
  type    = "A"
  ttl     = 60
  records = ["129.153.171.36"]

  #  alias {
  #    name                   = aws_lb.lb_external.dns_name
  #    zone_id                = aws_lb.lb_external.zone_id
  #    evaluate_target_health = false
  #  }
}

resource "aws_route53_record" "external_validation" {
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.external.id
    }
  }
  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = each.value.zone_id
  ttl     = 60
}
