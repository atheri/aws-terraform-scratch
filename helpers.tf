data "external" "elb-endpoint" {
  depends_on = [helm_release.this]
  program    = ["bash", "scripts/get_elb_endpoint.sh"]
}

output "elb-endpoint" {
  value = data.external.elb-endpoint.result.hostname
}

resource "null_resource" "update-local-kubeconfig" {
  triggers = {
    eks-cluster = aws_eks_cluster.this.endpoint
    script-sha = filesha1("scripts/get_elb_endpoint.sh")
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name}"
  }
}

