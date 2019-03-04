data "aws_availability_zones" "available" {}

locals {
  autoscaling_enabled  = "true"
  api_cpu              = 256
  api_mem              = 512
  api_count            = 1
  api_autoscale_min    = 1
  api_autoscale_max    = 3
  worker_cpu           = 256
  worker_mem           = 512
  worker_count         = 1
  worker_autoscale_min = 1
  worker_autoscale_max = 3
}

data "aws_iam_role" "ecs_task" {
  name = "ecsTaskExecutionRole"
}

# API -------------------------------------------------------------------------

resource "aws_security_group" "ecs_api" {
  vpc_id = "${var.vpc_id}"
  name   = "${var.namespace}-ecs-api-sg"

  tags {
    Environment = "${var.stage}"
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ecs_api.id}"
}

data "template_file" "api_task" {
  template = "${file("${path.module}/tasks/api_definition.json")}"

  vars {
    container_port = "${var.container_port}"
    host_port      = "${var.container_port}"
    redis_hostname = "${aws_elasticache_cluster.jobqr.cache_nodes.0.address}"
    redis_port     = "${var.redis_port}"
    repository_url = "${module.ecr_api.registry_url}"
    ecr_region     = "${var.region}"
    log_group      = "${aws_cloudwatch_log_group.api_workers.name}"
    log_region     = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.namespace}-api"
  container_definitions    = "${data.template_file.api_task.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${local.api_cpu}"
  memory                   = "${local.api_mem}"
  execution_role_arn       = "${data.aws_iam_role.ecs_task.arn}"
  task_role_arn            = "${data.aws_iam_role.ecs_task.arn}"
}

resource "aws_ecs_service" "api" {
  name            = "${var.namespace}-api"
  task_definition = "${aws_ecs_task_definition.api.arn}"
  desired_count   = "${local.api_count}"
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.ecs.id}"

  network_configuration {
    security_groups = ["${aws_security_group.ecs_api.id}"]

    /* With X subnets, ECS will create X instances even if X > desired count */
    subnets          = ["${var.subnet_ids[0]}"]
    assign_public_ip = true
  }

  /* See below for LB setup */
  load_balancer {
    target_group_arn = "${aws_alb_target_group.api.id}"
    container_name   = "api"
    container_port   = "${var.container_port}"
  }

  #depends_on[""]
}

resource "aws_appautoscaling_target" "api" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "${data.aws_iam_role.ecs_task.arn}"
  min_capacity       = "${local.api_autoscale_min}"
  max_capacity       = "${local.api_autoscale_max}"
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "api-up" {
  name               = "api_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.api"]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "api-down" {
  name               = "api_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.api"]
}

# Cloudwatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "api_service_cpu_high" {
  alarm_name          = "api_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs.name}"
    ServiceName = "${aws_ecs_service.api.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.api-up.arn}"]
}

# # Cloudwatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "api_service_cpu_low" {
  alarm_name          = "api_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs.name}"
    ServiceName = "${aws_ecs_service.api.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.api-down.arn}"]
}

# Worker ----------------------------------------------------------------------

resource "aws_security_group" "ecs_worker" {
  vpc_id = "${var.vpc_id}"
  name   = "${var.namespace}-ecs-worker-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment = "${var.stage}"
  }
}

data "template_file" "worker_task" {
  template = "${file("${path.module}/tasks/worker_definition.json")}"

  vars {
    redis_hostname = "${aws_elasticache_cluster.jobqr.cache_nodes.0.address}"
    redis_port     = "${var.redis_port}"
    repository_url = "${module.ecr_worker.registry_url}"
    ecr_region     = "${var.region}"
    log_group      = "${aws_cloudwatch_log_group.api_workers.name}"
    log_region     = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.namespace}-worker"
  container_definitions    = "${data.template_file.worker_task.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${local.worker_cpu}"
  memory                   = "${local.worker_mem}"
  execution_role_arn       = "${data.aws_iam_role.ecs_task.arn}"
  task_role_arn            = "${data.aws_iam_role.ecs_task.arn}"
}

resource "aws_ecs_service" "worker" {
  name            = "${var.namespace}-worker"
  task_definition = "${aws_ecs_task_definition.worker.arn}"
  desired_count   = "${local.worker_count}"
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.ecs.id}"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_worker.id}"]
    subnets          = ["${var.subnet_ids}"]
    assign_public_ip = true
  }
}

resource "aws_appautoscaling_target" "worker" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "${data.aws_iam_role.ecs_task.arn}"
  min_capacity       = "${local.worker_autoscale_min}"
  max_capacity       = "${local.worker_autoscale_max}"
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "worker-up" {
  name               = "worker_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.worker"]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "worker-down" {
  name               = "worker_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.worker"]
}

# Cloudwatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "worker_service_cpu_high" {
  alarm_name          = "worker_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs.name}"
    ServiceName = "${aws_ecs_service.worker.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.worker-up.arn}"]
}

# # Cloudwatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "worker_service_cpu_low" {
  alarm_name          = "worker_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs.name}"
    ServiceName = "${aws_ecs_service.worker.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.worker-down.arn}"]
}
