terraform {
  required_version = ">= 1.3.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.22.0"
    }
  }
}

resource "docker_image" "gparse-dev" {
  name         = "gparse-dev"
  keep_locally = true
  triggers = {
    dockerfile_hash = filesha256("Dockerfile")
  }
  build {
    path = "."
    tag  = ["gparse-dev"]
  }
}

resource "docker_container" "gparse-dev" {
  image   = docker_image.gparse-dev.image_id
  name    = "gparse-dev"
  command = ["morbo", "src/gparse.pl"]
  ports {
    internal = 3000
    external = 3000
  }
}
