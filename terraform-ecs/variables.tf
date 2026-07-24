variable "apps" {
  description = "Configuration for each application"
  type = map(object({
    image  = string
    port   = number
    cpu    = number
    memory = number
  }))

  default = {
    nginx = {
      image  = "arslanbhatti123/nginx-app:latest"
      port   = 81
      cpu    = 256
      memory = 512
    }
    nodejs = {
      image  = "arslanbhatti123/nodejs-app:latest"
      port   = 3000
      cpu    = 256
      memory = 512
    }
    flask = {
      image  = "arslanbhatti123/flask-app:latest"
      port   = 5000
      cpu    = 256
      memory = 512
    }
    java = {
      image  = "arslanbhatti123/java-app:latest"
      port   = 8080
      cpu    = 512
      memory = 1024
    }
    frontend = {
      image  = "arslanbhatti123/fullstack-frontend:latest"
      port   = 80
      cpu    = 256
      memory = 512
    }
  }
}

variable "db_password" {
  description = "Password for RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}
