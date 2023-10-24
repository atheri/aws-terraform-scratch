resource "aws_iam_role" "eks-cluster" {
  name               = "${var.env}-eks-cluster"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks-cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name       = var.env
  version    = "1.28"
  role_arn   = aws_iam_role.eks-cluster.arn
  vpc_config {
    subnet_ids = var.private-subnet-ids
  }
}

resource "aws_eks_addon" "vpc-cni" {
  addon_name   = "vpc-cni"
  cluster_name = aws_eks_cluster.this.name
  preserve     = true
}

resource "aws_eks_addon" "coredns" {
  depends_on   = [aws_eks_node_group.this] # coredns won't be healthy without nodes
  addon_name   = "coredns"
  cluster_name = aws_eks_cluster.this.name
  preserve     = true
}

resource "aws_eks_addon" "kube-proxy" {
  addon_name   = "kube-proxy"
  cluster_name = aws_eks_cluster.this.name
  preserve     = true
}

### nodes ###
resource "aws_iam_role" "eks-node" {
  name               = "${aws_eks_cluster.this.name}-eks-node"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-node" {
  for_each = toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonEKS_CNI_Policy"
  ])
  role       = aws_iam_role.eks-node.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_eks_node_group" "this" {
  node_group_name_prefix = "${aws_eks_cluster.this.name}-"
  cluster_name           = aws_eks_cluster.this.name
  node_role_arn          = aws_iam_role.eks-node.arn
  subnet_ids             = aws_eks_cluster.this.vpc_config[0].subnet_ids
  instance_types         = ["t3.medium"]
  ami_type               = "AL2_x86_64"
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
}

### IRSA ###
data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  tags            = {
    Name = "${aws_eks_cluster.this.name}-eks-irsa"
  }
}