output "frontend_cloudfront_id" {
  value = "${module.cdn.cf_id}"
}

output "frontend_cloudfront_bucket" {
  value = "${module.cdn.s3_bucket}"
}

output "frontend_cloudfront_bucket_domain" {
  value = "${module.cdn.s3_bucket_domain_name}"
}
