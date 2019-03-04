# resource "aws_lb" "public" {
#   load_balancer_type = "application"
#   security_groups    = ["${aws_security_group.lb_public.id}"]
#   subnets            = ["${var.subnet_ids}"]

#   #enable_deletion_protection = true
# }

resource "aws_alb" "main" {
  name = "${var.namespace}-${var.stage}-alb"

  # launch lbs in public or private subnets based on "internal" variable
  #internal        = "${var.internal}"
  security_groups    = ["${aws_security_group.lb_public.id}"]
  subnets            = ["${var.subnet_ids}"]  
  #subnets         = "${split(",", var.internal == true ? var.private_subnets : var.public_subnets)}"
  # security_groups = ["${aws_security_group.nsg_lb.id}"]
  # tags            = "${var.tags}"

  # enable access logs in order to get support from aws
  # access_logs {
  #   enabled = true
  #   bucket  = "${aws_s3_bucket.lb_access_logs.bucket}"
  # }
}

resource "aws_security_group" "lb_public" {
  name   = "${var.namespace}-lb-public"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    
  }
  egress {
    from_port       = "${var.container_port}"
    to_port         = "${var.container_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ecs_api.id}"]
  }
  
  tags {
    Environment = "${var.stage}"
  }
}

resource "aws_security_group_rule" "allow_into_api_from_lb" {
  type                     = "ingress"
  from_port                =  "${var.container_port}"
  to_port                  =  "${var.container_port}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.ecs_api.id}"
  source_security_group_id = "${aws_security_group.lb_public.id}"
}


resource "aws_alb_target_group" "api" {
  name        = "${var.namespace}-api-tg"
  port        =  "${var.container_port}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  health_check {
    path    = "/"
    matcher = 200
  }
  depends_on = ["aws_alb.main"]
}

resource "aws_alb_listener" "public_http" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.api.id}"
    type             = "forward"
  }
    depends_on = ["aws_alb.main"]
}

resource "aws_alb_listener" "public_https" {
  load_balancer_arn = "${aws_alb.main.arn}"
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "${var.certificate_arn}"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # count             = "${contains(var.protocols, "HTTPS") ? 1 : 0}"

  default_action {
    target_group_arn = "${aws_alb_target_group.api.id}"
    type             = "forward"
  }

  depends_on = ["aws_alb.main"]
}
