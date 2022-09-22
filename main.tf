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
  name         = "${local.app_name}-image"
  keep_locally = true
  triggers = {
    source_code_hash = sha256(join("", [for source_file in fileset(path.module, "**") : filesha256(source_file)]))
  }
  build {
    path = path.module
    tag  = [local.app_name]
  }
}

resource "docker_container" "gparse-dev" {
  image   = resource.docker_image.gparse-dev.image_id
  name    = "${local.app_name}-container"
  command = ["morbo", "src/gparse.pl"]
  ports {
    internal = 3000
    external = 3000
  }
}
