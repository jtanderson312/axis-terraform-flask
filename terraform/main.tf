data "aws_route53_zone" "selected" {
  name = "${var.domain_name}."
}

output "r53_zoneid" {
  value = "${data.aws_route53_zone.selected.zone_id}"
}

output "r53_name" {
  value = "${data.aws_route53_zone.selected.name}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "subnet_zones" {
  value = "${data.aws_availability_zones.available.names}"
}

data "aws_region" "current" {}

output "region" {
  value = "${data.aws_region.current.name}"
}

module "acm_request_certificate" {
  source                    = "git::https://github.com/cloudposse/terraform-aws-acm-request-certificate.git?ref=tags/0.1.3"
  domain_name               = "${var.domain_name}"
  subject_alternative_names = ["*.${var.domain_name}"]
  ttl                       = "60"
}

module "frontend" "react" {
  source          = "./modules/frontend"
  namespace       = "${var.namespace}"
  stage           = "${var.stage}"
  domain_name     = "${var.domain_name}"
  certificate_arn = "${module.acm_request_certificate.arn}"
}

module "network" {
  source     = "./modules/network"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  cidr_block = "${var.cidr_block}"
}

module "backend" {
  source          = "./modules/backend"
  namespace       = "${var.namespace}"
  stage           = "${var.stage}"
  vpc_id          = "${module.network.vpc_id}"
  subnet_ids      = ["${module.network.public_subnet_ids}"]
  region          = "${var.region}"
  domain_name     = "${var.domain_name}"
  certificate_arn = "${module.acm_request_certificate.arn}"
}

# Export configuration file data
data "template_file" "aws_config" {
  template = "${file("${path.module}/aws_config.tpl")}"

  vars {
    ecs_cluster               = "${module.backend.ecs_cluster}"
    api_url                   = "${module.backend.ecr_api_url}"
    worker_url                = "${module.backend.ecr_worker_url}"
    frontend_dist_id          = "${module.frontend.frontend_cloudfront_id}"
    frontend_s3_bucket        = "${module.frontend.frontend_cloudfront_bucket}"
    frontend_s3_bucket_domain = "${module.frontend.frontend_cloudfront_bucket_domain}"
  }
}

resource "local_file" "aws_config" {
  content  = "${data.template_file.aws_config.rendered}"
  filename = "${path.module}/../aws.env"
}
