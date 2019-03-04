output "ecr_api_url" {
    value = "${module.ecr_api.registry_url}"
}

output "ecr_worker_url" {
    value = "${module.ecr_worker.registry_url}"
}

output "ecs_cluster" {
    value = "${aws_ecs_cluster.ecs.name}"
}
