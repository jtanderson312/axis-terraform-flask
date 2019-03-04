
resource "aws_ecs_cluster" "ecs" {
  name  = "${var.namespace}-${var.stage}-cluster"
  # count = "${var.ecs_enabled == "true" ? 1 : 0}"
}
