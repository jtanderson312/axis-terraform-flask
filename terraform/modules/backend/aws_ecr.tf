module "ecr_api" {
  source     = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=master"
  name       = "${var.namespace}-api"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  attributes = "${compact(concat(var.attributes, list("ecr")))}"


  #use_fullname = "${var.use_fullname}"
  use_fullname = "false"
  max_image_count = 5
}

module "ecr_worker" {
  source     = "git::https://github.com/cloudposse/terraform-aws-ecr.git?ref=master"
  name       = "${var.namespace}-worker"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  attributes = "${compact(concat(var.attributes, list("ecr")))}"


  #use_fullname = "${var.use_fullname}"
  use_fullname = "false"
  max_image_count = 5
}
