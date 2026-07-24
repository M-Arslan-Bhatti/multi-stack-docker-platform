resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend-container"
      image     = "arslanbhatti123/fullstack-backend:latest"
      essential = true
      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "POSTGRES_DB"
          value = "textdb"
        },
        {
          name  = "POSTGRES_USER"
          value = "appuser"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = var.db_password
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/backend"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  tags = {
    Name = "backend-task"
  }
}

resource "aws_ecs_service" "backend" {
  name                   = "backend-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition         = aws_ecs_task_definition.backend.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  enable_execute_command  = true

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend-container"
    container_port   = 5000
  }

  depends_on = [aws_db_instance.postgres, aws_lb_listener.backend]

  tags = {
    Name = "backend-service"
  }
}
