resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}-cluster"

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - ECS - cluster"
    }
  )
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.name}/service"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - ECS - LogGroup"
    }
  )
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.name}-task-def"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.execute_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EXTERNAL"] # FARGATE
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode(
    [
      {
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.log_group.name
            awslogs-region        = data.aws_region.this.name
            awslogs-stream-prefix = "nginx"
          }
        }
        portMappings = [
          {
            hostPort      = 443
            protocol      = "tcp"
            containerPort = 443
          }
        ]
        environment = [
          {
            name  = "NAME"
            value = var.name
          }
        ]
        memoryReservation = 300
        stopTimeout       = 20
        image             = "${aws_ecr_repository.this.repository_url}:default"
        startTimeout      = 30
        name              = "nginx-service"
        #        mountPoints = [
        #          {
        #            containerPath = "/data"
        #            sourceVolume  = "share"
        #          }
        #        ]
        #        volumes = [
        #          {
        #            host = {
        #              sourcePath = "/data"
        #            }
        #            name = "share"
        #          }
        #        ]
      }
  ])

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - ECS - task def",
    }
  )
}


resource "aws_ecs_service" "service" {
  name = "${var.name}-ecs-service"

  cluster         = aws_ecs_cluster.cluster.id
  desired_count   = 1
  launch_type     = "EXTERNAL" # FARGATE
  task_definition = "${aws_ecs_task_definition.task_definition.family}:${aws_ecs_task_definition.task_definition.revision}"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  #  platform_version                   = "1.4.0"
  #  propagate_tags                     = "TASK_DEFINITION"
  #  health_check_grace_period_seconds  = 300

  #  load_balancer {
  #    target_group_arn = aws_lb_target_group.external_target_group.arn
  #    container_name   = "${var.name}-service"
  #    container_port   = 443
  #  }
  #
  #  network_configuration {
  #    subnets          = local.ecs_subnet_ids
  #    security_groups  = [aws_security_group.ecs_service.id]
  #    assign_public_ip = true
  #  }

  deployment_controller {
    type = "ECS"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - ECS Service"
    }
  )
}


resource "aws_security_group" "ecs_service" {
  name   = "${var.name}-SG"
  vpc_id = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name} - ECS SG"
    }
  )
}

resource "aws_security_group_rule" "ecs_service_traffic_internal" {
  description              = "${var.name} - internal port"
  source_security_group_id = aws_security_group.alb_external.id
  security_group_id        = aws_security_group.ecs_service.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  type                     = "ingress"
}

resource "aws_security_group_rule" "ecs_service_traffic_external_egress" {
  description = "${var.name} - external egress"

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id

  from_port = 0
  to_port   = 65535

  protocol = "-1"
  type     = "egress"
}
