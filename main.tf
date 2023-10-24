terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      "created" = "terraform"
      "env"     = "prod"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
  registry_auth {
    address  = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${data.aws_region.this.name}.amazonaws.com"
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name]
      command     = "aws"
    }
  }
  experiments {
    manifest = true
  }
}

locals {
  env = "prod"
}

data "aws_region" "this" {}
data "aws_caller_identity" "this" {}
data "aws_ecr_authorization_token" "this" {}
