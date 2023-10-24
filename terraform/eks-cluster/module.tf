variable "env" {}
variable "private-subnet-ids" {}

output "aws_eks_cluster" {
  value = aws_eks_cluster.this
}