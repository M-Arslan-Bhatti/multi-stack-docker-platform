resource "aws_ecs_service" "apps" {
  for_each = var.apps

  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.apps[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.apps[each.key].arn
    container_name   = "${each.key}-container"
    container_port   = each.value.port
  }

  depends_on = [aws_lb_listener.apps]

  tags = {
    Name = "${each.key}-service"
  }
}