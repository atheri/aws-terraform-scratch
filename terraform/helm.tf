resource "helm_release" "this" {
  depends_on = [module.eks-cluster]
  name       = "echo-server"
  chart      = "./../application/helm/service"
  namespace  = "default"
  values = [
    file("./../application/src/values.yaml")
  ]
  set {
    name  = "image"
    value = docker_registry_image.echo-server.name
  }
}
