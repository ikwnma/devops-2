variable "aws_region" {
  description = "Region de AWS donde se desplegará la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto."
  type        = string
  default     = "devops-u2"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS."
  type        = string
  default     = "devops-u2-eks"
}

variable "vpc_cidr" {
  description = "CIDR principal de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR de las subredes publicas."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "node_instance_types" {
  description = "Tipos de instancia para los nodos del cluster EKS."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Cantidad deseada de nodos."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Cantidad minima de nodos."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Cantidad maxima de nodos."
  type        = number
  default     = 3
}
