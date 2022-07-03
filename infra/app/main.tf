# Setup ALB resources for App
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

# Setup IAM resources for ECS/Lambda
data "aws_iam_policy_document" "execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "AllowCreateNetworkInterface"
    actions   = ["ec2:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "execution_role" {
  name                = "servianExecutionRole"
  assume_role_policy  = data.aws_iam_policy_document.execution_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]

  inline_policy {
    name   = "LambdaRequiredPermissions"
    policy = data.aws_iam_policy_document.lambda.json
  }
}

# Setup ECS/Lambda resources
resource "aws_ecs_task_definition" "app" {
  family                   = "servian-tech-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution_role.arn

  container_definitions = templatefile(
    "${path.module}/task_definition.json",
    {
      db_host   = var.db_config.db_host,
      db_pass   = var.db_config.db_pass,
      db_user   = var.db_config.db_user,
      image_uri = var.image_uri,
    }
  )

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_lambda_function" "init_db" {
  function_name = "servian-init-db"
  role          = aws_iam_role.execution_role.arn
  image_uri     = "${var.image_uri}:latest"
  package_type  = "Image"

  environment {
    variables = {
      VTT_DBHOST     = var.db_config.db_host
      VTT_DBNAME     = "servian_tech_app"
      VTT_DBPASSWORD = var.db_config.db_pass
      VTT_DBPORT     = "5432"
      VTT_DBUSER     = var.db_config.db_user
      VTT_LISTENHOST = "0.0.0.0"
      VTT_LISTENPORT = "80"
    }
  }

  image_config {
    command = ["updatedb"]
  }

  vpc_config {
    subnet_ids         = var.app_subnets
    security_group_ids = ["${var.app_sg}"]
  }
}

resource "aws_ecs_cluster" "app" {
  name = "ServianTechApp"
}

resource "aws_ecs_service" "app" {
  name            = "servian-tech-app"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
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

# Configure autoscaling for ECS app
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "AutoScaleApp"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

output "endpoint_url" {
  value = aws_lb.app.dns_name
}
