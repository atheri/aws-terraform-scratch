resource "aws_ecr_repository" "this" {
  name         = "echo-server"
  force_delete = true
}

locals {
  source-code-sha = sha1(join("", [for f in fileset(path.module, "src/*") : filesha1(f)]))
}

resource "docker_image" "this" {
  name = aws_ecr_repository.this.repository_url
  build {
    context = "./echo-server"
    tag     = ["${aws_ecr_repository.this.repository_url}:${local.source-code-sha}"]
  }
  triggers = {
    dir_sha1 = local.source-code-sha
  }
}

resource "docker_registry_image" "echo-server" {
  name          = "${docker_image.this.name}:${local.source-code-sha}"
  keep_remotely = true
}