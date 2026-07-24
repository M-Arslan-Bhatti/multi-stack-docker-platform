output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_names" {
  value = [for s in aws_ecs_service.apps : s.name]
}