variable "namespace" {
  type        = "string"
  description = "Namespace (e.g. eg)"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "certificate_arn" {
  type        = "string"
  default     = ""
  description = "Certificate ARN"
}

variable "domain_name" {
  type        = "string"
  default     = "example.com"
  description = "DNS Domain name registered with route53"
}

data "aws_route53_zone" "selected" {
  name = "${var.domain_name}."
}

module "cdn" {
  source                 = "git::https://github.com/cloudposse/terraform-aws-cloudfront-s3-cdn.git?ref=master"
  namespace              = "${var.namespace}"
  stage                  = "${var.stage}"
  name                   = "frontend"
  acm_certificate_arn    = "${var.certificate_arn}"
  aliases                = ["www.${var.domain_name}"]
  parent_zone_id         = "${data.aws_route53_zone.selected.zone_id}"
  viewer_protocol_policy = "redirect-to-https"
  default_root_object    = "index.html"
  cors_allowed_origins   = ["*"]
}

resource "aws_s3_bucket_object" "index" {
  bucket       = "${module.cdn.s3_bucket}"
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = "${md5(file("${path.module}/index.html"))}"
}
