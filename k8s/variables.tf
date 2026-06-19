############################
# AWS Region
############################

variable "aws_region" {
  description = "AWS region"
  type        = string
}

############################
# EKS Cluster
############################

variable "eks_cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  type        = string
}

variable "eks_cluster_ca_certificate" {
  description = "EKS Cluster CA certificate"
  type        = string
  sensitive   = true
}

############################
# Project
############################

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "production"
}

############################
# Kubernetes Deployments
############################

variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 2
}

variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
}

variable "backend_port" {
  description = "Backend service port"
  type        = number
  default     = 8080
}

variable "frontend_port" {
  description = "Frontend service port"
  type        = number
  default     = 3000
}

############################
# Backend Resources
############################

variable "backend_cpu_request" {
  description = "Backend CPU request"
  type        = string
  default     = "250m"
}

variable "backend_memory_request" {
  description = "Backend memory request"
  type        = string
  default     = "512Mi"
}

variable "backend_cpu_limit" {
  description = "Backend CPU limit"
  type        = string
  default     = "500m"
}

variable "backend_memory_limit" {
  description = "Backend memory limit"
  type        = string
  default     = "1Gi"
}

############################
# Frontend Resources
############################

variable "frontend_cpu_request" {
  description = "Frontend CPU request"
  type        = string
  default     = "100m"
}

variable "frontend_memory_request" {
  description = "Frontend memory request"
  type        = string
  default     = "256Mi"
}

variable "frontend_cpu_limit" {
  description = "Frontend CPU limit"
  type        = string
  default     = "200m"
}

variable "frontend_memory_limit" {
  description = "Frontend memory limit"
  type        = string
  default     = "512Mi"
}

############################
# Database Configuration
############################

variable "db_url" {
  description = "Database connection URL"
  type        = string
  default     = "jdbc:mysql://mysql-service:3306/despachos"
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

############################
# Autoscaling Configuration
############################

variable "backend_min_replicas" {
  description = "Minimum number of backend replicas"
  type        = number
  default     = 2
}

variable "backend_max_replicas" {
  description = "Maximum number of backend replicas"
  type        = number
  default     = 5
}

variable "backend_cpu_target_percentage" {
  description = "Target CPU utilization percentage for backend HPA"
  type        = number
  default     = 70
}

variable "backend_memory_target_percentage" {
  description = "Target memory utilization percentage for backend HPA"
  type        = number
  default     = 80
}

variable "frontend_min_replicas" {
  description = "Minimum number of frontend replicas"
  type        = number
  default     = 2
}

variable "frontend_max_replicas" {
  description = "Maximum number of frontend replicas"
  type        = number
  default     = 4
}

variable "frontend_cpu_target_percentage" {
  description = "Target CPU utilization percentage for frontend HPA"
  type        = number
  default     = 70
}

variable "frontend_memory_target_percentage" {
  description = "Target memory utilization percentage for frontend HPA"
  type        = number
  default     = 80
}

############################
# ALB Controller
############################

variable "alb_controller_role_arn" {
  description = "ARN of ALB Controller IAM Role"
  type        = string
}

############################
# ECR
############################

variable "ecr_registry_id" {
  description = "ECR Registry ID (AWS Account ID)"
  type        = string
}
