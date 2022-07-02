resource "aws_lb" "app" {
  security_groups = ["${var.alb_sg}"]
  subnets         = var.alb_subnets
}

resource "aws_lb_target_group" "app" {
  vpc_id      = var.vpc_id
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"

  health_check {
    matcher = "200"
    path    = "/healthcheck"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "servian-tech-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 1024

  container_definitions = templatefile(
    "${path.module}/task_definition.json",
    {
      db_host = var.db_config.db_host,
      db_name = var.db_config.db_name,
      db_pass = var.db_config.db_pass,
      db_user = var.db_config.db_user,
      image_url = var.image_url,
    }
  )

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_cluster" "app" {
  name = "ServianTechApp"
}

resource "aws_ecs_service" "app" {
  name            = "servian-tech-app"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "servian-tech-app"
    container_port   = 80
  }

  network_configuration {
    subnets         = var.app_subnets
    security_groups = ["${var.app_sg}"]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

output "endpoint_url" {
  value = aws_lb.app.dns_name
}
