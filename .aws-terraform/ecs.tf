data "aws_ssm_parameter" "db_host" {
  name = "db_host"
}

data "aws_ssm_parameter" "nginx_ecr_repo_uri" {
  name = "nginx_ecr_repo_uri"
}

data "aws_ssm_parameter" "rails_ecr_repo_uri" {
  name = "rails_ecr_repo_uri"
}

data "aws_ssm_parameter" "secret_key_base" {
  name = "secret_key_base"
}

resource "aws_ecs_cluster" "nature_sounds_cluster" {
  name = "nature_sounds_prod_cluster"
}

resource "aws_ssm_parameter" "youtube_api_key" {
  name = "youtube_api_key"
}

locals {
  container_definitions = jsondecode(templatefile("${path.module}/task-definition.json", {
    rails_ecr_repo_uri = data.aws_ssm_parameter.rails_ecr_repo_uri.value,
    nginx_ecr_repo_uri = data.aws_ssm_parameter.nginx_ecr_repo_uri.value,
    db_host = data.aws_ssm_parameter.db_host.value,
    db_username = data.aws_ssm_parameter.db_username.value,
    db_password = data.aws_ssm_parameter.db_password.value,
    secret_key_base = data.aws_ssm_parameter.secret_key_base.value,
    alb_dns_name = aws_lb.app_alb.dns_name,
    execution_role_arn = var.execution_role_arn,
    task_role_arn = var.task_role_arn,
    youtube_api_key = var.youtube_api_key
  }))["containerDefinitions"]
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "task_family"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
  container_definitions = jsonencode(local.container_definitions)
}

resource "aws_ecs_service" "nature_sounds_service" {
  name            = "nature-sounds-service"
  cluster         = aws_ecs_cluster.nature_sounds_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = [aws_subnet.public_web_subnet1.id, aws_subnet.public_web_subnet2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "nginx"
    container_port   = 80
  }

  health_check_grace_period_seconds = 300
}

resource "aws_security_group" "ecs_tasks_sg" {
  name   = "ecs_tasks_sg"
  vpc_id = aws_vpc.main_app_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_tasks_sg"
  }
}

resource "aws_security_group_rule" "ecs_tasks_sg_rule" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_cloudwatch_log_group" "awslogs-group" {
  name              = "awslogs-group"
  retention_in_days = 7
}
