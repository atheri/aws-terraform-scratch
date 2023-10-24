resource "helm_release" "this" {
  depends_on = [aws_eks_node_group.this]
  name       = "echo-server"
  chart      = "./helm/service"
  namespace  = "default"
  values = [
    file("./echo-server/values.yaml")
  ]
  set {
    name  = "image"
    value = docker_registry_image.echo-server.name
  }
}
