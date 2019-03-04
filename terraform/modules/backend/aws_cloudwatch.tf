resource "aws_cloudwatch_log_group" "api_workers" {
  name              = "${var.namespace}-api"
  retention_in_days = 7
  tags              = "${merge(map("env","${var.stage}"), var.tags)}"
}
