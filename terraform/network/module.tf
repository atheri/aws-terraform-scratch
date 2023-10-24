variable "env" {}

data "aws_region" "this" {}

output "private-subnet-ids" {
  value = [for s in aws_subnet.private : s.id]
}