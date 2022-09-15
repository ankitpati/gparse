terraform {
  required_version = ">= 1.2.9"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.21.0"
    }
  }
}

resource "docker_image" "gparse-dev" {
  name         = "gparse-dev"
  keep_locally = true
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
