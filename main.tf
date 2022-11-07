terraform {
  required_version = ">= 1.3.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.22.0"
    }
  }
}

locals {
  app_name = "gparse-dev"
}

resource "docker_image" "gparse-dev" {
  name         = local.app_name
  keep_locally = true
  triggers = {
    dockerfile_hash = filesha256("Dockerfile")
  }
  build {
    path = path.module
  }
}

resource "docker_container" "gparse-dev" {
  image   = resource.docker_image.gparse-dev.image_id
  name    = local.app_name
  command = ["morbo", "src/gparse.pl"]
  ports {
    internal = 3000
    external = 3000
  }
}
