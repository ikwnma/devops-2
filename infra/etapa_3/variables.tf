variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  default     = "devops-u2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  default     = "1.29"
}

variable "node_count" {
  description = "Number of worker nodes"
  default     = 2
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  default     = "t3.medium"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.1.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  default     = true
}
