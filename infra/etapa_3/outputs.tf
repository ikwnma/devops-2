output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "EKS Cluster version"
  value       = aws_eks_cluster.main.version
}

output "eks_cluster_ca_certificate" {
  description = "EKS Cluster CA Certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "eks_node_group_id" {
  description = "EKS Node Group ID"
  value       = aws_eks_node_group.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "Private Subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "public_subnets" {
  description = "Public Subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "alb_controller_role_arn" {
  description = "ARN of ALB Controller IAM Role"
  value       = aws_iam_role.alb_controller.arn
}

output "configure_kubectl" {
  description = "Configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

############################
# ECR Outputs
############################

output "ecr_frontend_repository_url" {
  description = "Frontend ECR Repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_repository_url" {
  description = "Backend ECR Repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repository_name" {
  description = "Frontend ECR Repository Name"
  value       = aws_ecr_repository.frontend.name
}

output "ecr_backend_repository_name" {
  description = "Backend ECR Repository Name"
  value       = aws_ecr_repository.backend.name
}

############################
# AWS Account ID (for ECR in k8s/)
############################

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

