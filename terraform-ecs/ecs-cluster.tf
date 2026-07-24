resource "aws_ecs_cluster" "main" {
  name = "multi-stack-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name = "multi-stack-cluster"
  }
}
