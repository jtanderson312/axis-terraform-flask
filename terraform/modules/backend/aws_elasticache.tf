

resource "aws_elasticache_subnet_group" "jobqr" {
  name       = "${var.namespace}-jobqr"
  subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_security_group" "jobqr" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.namespace}-elasticache-jobqr-sg"

  ingress {
    from_port       = "${var.redis_port}"
    to_port         = "${var.redis_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ecs_api.id}",
                       "${aws_security_group.ecs_worker.id}"]
  }

  tags {
    Environment = "${var.stage}"
  }
}

resource "aws_elasticache_cluster" "jobqr" {
  cluster_id           = "${var.namespace}-jobqr"
  engine               = "redis"
  availability_zone    = "${data.aws_availability_zones.available.names[0]}"
  subnet_group_name    = "${aws_elasticache_subnet_group.jobqr.name}"
  security_group_ids   = ["${aws_security_group.jobqr.id}"]
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  port                 = "${var.redis_port}"
  apply_immediately    = true
}