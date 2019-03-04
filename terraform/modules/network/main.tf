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

variable "cidr_block" {
  type        = "string"
  description = "Classless Inter-Domain Routing block"
}

# variable "region" {
#   type        = "string"
#   description = "Region for VPC"
# }

locals {
  max_availability_zones = 2
}

module "label" {
  source = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.2.1"

  namespace  = "${var.namespace}"
  name       = "network"
  stage      = "${var.stage}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# output "subnet_zones" {
#   value = "${data.aws_availability_zones.available.names}"
# }

data "aws_region" "current" {}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
  namespace  = "${module.label.namespace}"
  stage      = "${module.label.stage}"
  name       = "${module.label.name}"
  cidr_block = "${var.cidr_block}"
}

module "subnets" {
  source    = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace = "${module.label.namespace}"
  stage     = "${module.label.stage}"
  name      = "${module.label.name}"

  #region              = "${var.region}"
  region              = "${data.aws_region.current.name}"
  availability_zones  = ["${slice(data.aws_availability_zones.available.names, 0, local.max_availability_zones)}"]
  vpc_id              = "${module.vpc.vpc_id}"
  igw_id              = "${module.vpc.igw_id}"
  cidr_block          = "${var.cidr_block}"
  nat_gateway_enabled = "false"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnet_ids" {
  value = ["${module.subnets.public_subnet_ids}"]
}

output "private_subnet_ids" {
  value = ["${module.subnets.private_subnet_ids}"]
}
