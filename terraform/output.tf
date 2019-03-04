# output "vpc_id" {
#   value = "${module.vpc.vpc_id}"
# }

# output "ecr_registry_id" {
#   value = "${module.ecr_web.registry_id}"
# }

# output "ecr_registry_url" {
#   value = "${module.ecr_web.registry_url}"
# }

# output "alb_dns_name" {
#   value = "${module.alb.alb_dns_name}"
# }

# output "ecs_arn" {
#   value = "${var.ecs_enabled == "true" ? element(concat(aws_ecs_cluster.ecs.*.arn, list("")), 0) : ""}"
# }

output "ecr_api_url"
{
    value = "${module.backend.ecr_api_url}"
}

output "ecr_worker_url"
{
    value = "${module.backend.ecr_worker_url}"
}