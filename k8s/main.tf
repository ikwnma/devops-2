terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_ca_certificate)
  token                  = data.aws_eks_auth.cluster.token

  load_config_file = false
}

provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_ca_certificate)
    token                  = data.aws_eks_auth.cluster.token

    load_config_file = false
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_auth" "cluster" {
  name = var.eks_cluster_name
}
