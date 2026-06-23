locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
    Platform    = "EKS"
  }

  ecr_repositories = [
    "frontend-despacho",
    "backend-ventas",
    "backend-despachos"
  ]
}
