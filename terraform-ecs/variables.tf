variable "apps" {
  description = "Configuration for each application"
  type = map(object({
    image             = string
    port              = number
    cpu               = number
    memory            = number
    health_check_path = string
  }))

  default = {
    nginx = {
      image             = "arslanbhatti123/nginx-app:latest"
      port              = 81
      cpu               = 256
      memory            = 512
      health_check_path = "/"
    }
    nodejs = {
      image             = "arslanbhatti123/nodejs-app:latest"
      port              = 3000
      cpu               = 256
      memory            = 512
      health_check_path = "/"
    }
    flask = {
      image             = "arslanbhatti123/flask-app:latest"
      port              = 5000
      cpu               = 256
      memory            = 512
      health_check_path = "/"
    }
    java = {
      image             = "arslanbhatti123/java-app:latest"
      port              = 8080
      cpu               = 512
      memory            = 1024
      health_check_path = "/hello"
    }
    frontend = {
      image             = "arslanbhatti123/fullstack-frontend:latest"
      port              = 80
      cpu               = 256
      memory            = 512
      health_check_path = "/"
    }
  }
}

variable "db_password" {
  description = "Password for RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}
