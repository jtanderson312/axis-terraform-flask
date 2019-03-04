data "aws_route53_zone" "selected" {
  name = "${var.domain_name}."
}

resource "aws_route53_record" "lb" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name = "api.${data.aws_route53_zone.selected.name}"
  type = "A"

  alias {
    name                   = "${aws_alb.main.dns_name}"
    zone_id                = "${aws_alb.main.zone_id}"
    evaluate_target_health = true
  }
}
