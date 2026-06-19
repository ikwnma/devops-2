############################
# Kubernetes Deployments Outputs
############################

output "backend_deployment_name" {
  description = "Backend Deployment Name"
  value       = kubernetes_deployment.backend.metadata[0].name
}

output "frontend_deployment_name" {
  description = "Frontend Deployment Name"
  value       = kubernetes_deployment.frontend.metadata[0].name
}

output "kubernetes_namespace" {
  description = "Kubernetes Namespace for Applications"
  value       = kubernetes_namespace.apps.metadata[0].name
}

############################
# Kubernetes Services Outputs
############################

output "backend_service_name" {
  description = "Backend Service Name"
  value       = kubernetes_service.backend.metadata[0].name
}

output "backend_service_endpoint" {
  description = "Backend Service Endpoint (internal)"
  value       = "${kubernetes_service.backend.metadata[0].name}.${kubernetes_namespace.apps.metadata[0].name}.svc.cluster.local"
}

output "frontend_service_name" {
  description = "Frontend Service Name"
  value       = kubernetes_service.frontend.metadata[0].name
}

############################
# ALB Ingress Outputs
############################

output "frontend_ingress_name" {
  description = "Frontend Ingress Name"
  value       = kubernetes_ingress_v1.frontend.metadata[0].name
}

output "alb_dns_name" {
  description = "ALB DNS Name for Frontend Access"
  value       = try(kubernetes_ingress_v1.frontend.status[0].load_balancer[0].ingress[0].hostname, "Waiting for ALB provisioning...")
}

output "frontend_public_url" {
  description = "Frontend Public URL"
  value       = try("http://${kubernetes_ingress_v1.frontend.status[0].load_balancer[0].ingress[0].hostname}", "URL will be available after ALB provisioning")
}

############################
# HPA Outputs
############################

output "backend_hpa_name" {
  description = "Backend HPA Name"
  value       = kubernetes_horizontal_pod_autoscaler_v2.backend.metadata[0].name
}

output "frontend_hpa_name" {
  description = "Frontend HPA Name"
  value       = kubernetes_horizontal_pod_autoscaler_v2.frontend.metadata[0].name
}

############################
# Secrets Outputs
############################

output "db_credentials_secret_name" {
  description = "Database Credentials Secret Name"
  value       = kubernetes_secret.db_credentials.metadata[0].name
}

output "ecr_credentials_secret_name" {
  description = "ECR Credentials Secret Name"
  value       = kubernetes_secret.ecr_credentials.metadata[0].name
}
