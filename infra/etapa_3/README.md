# EKS Cluster Infrastructure (etapa_3)

Esta carpeta contiene la configuración de Terraform para crear un cluster EKS (Elastic Kubernetes Service) en AWS.

## Estructura de Archivos

- **main.tf** - Configuración del provider AWS
- **variables.tf** - Variables de entrada personalizables
- **vpc.tf** - VPC, subredes, Internet Gateway, NAT Gateway y Security Groups
- **iam.tf** - Roles IAM necesarios para EKS, nodes y ALB Controller
- **eks.tf** - Definición del cluster EKS y Managed Node Group
- **outputs.tf** - Outputs principales del cluster

## Requisitos

- Terraform >= 1.0
- AWS CLI configurado con credenciales válidas
- AWS Academy o Educate account
- kubectl instalado (para conectarse al cluster)

## Estructura de Red

```
VPC: 10.1.0.0/16
├── Public Subnets (para ALB)
│   ├── 10.1.1.0/24 (us-east-1a)
│   └── 10.1.2.0/24 (us-east-1b)
├── Private Subnets (para nodos worker)
│   ├── 10.1.10.0/24 (us-east-1a)
│   └── 10.1.11.0/24 (us-east-1b)
├── NAT Gateway (en subnet pública)
├── Internet Gateway
└── Route Tables (público y privado)
```

## Variables Personalizables

En **variables.tf** puedes ajustar:

```hcl
aws_region          = "us-east-1"     # Región AWS
project_name        = "devops-u2"     # Nombre del proyecto
kubernetes_version  = "1.29"          # Versión de Kubernetes
node_count          = 2               # Cantidad de nodos worker
node_instance_type  = "t3.medium"     # Tipo de instancia EC2
vpc_cidr            = "10.1.0.0/16"   # CIDR del VPC
enable_nat_gateway  = true            # Habilitar NAT Gateway
```

## Pasos para Desplegar

### 1. Inicializar Terraform

```bash
cd infra/etapa_3
terraform init
```

### 2. Planificar el despliegue

```bash
terraform plan -out=tfplan
```

### 3. Aplicar la configuración

```bash
terraform apply tfplan
```

El despliegue tarda aproximadamente **10-15 minutos**.

### 4. Configurar kubectl

Una vez que Terraform termine, ejecuta:

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-u2-eks
```

### 5. Verificar la conexión

```bash
kubectl get nodes
kubectl get pods -A
```

## Componentes Creados

### Infraestructura de Red
- ✅ VPC con 2 subredes públicas y 2 privadas
- ✅ Internet Gateway
- ✅ NAT Gateway (para tráfico saliente desde nodos privados)
- ✅ Route Tables y asociaciones
- ✅ Security Groups para cluster y nodos

### Cluster EKS
- ✅ Cluster EKS con Kubernetes 1.29 (personalizable)
- ✅ Managed Node Group con 2 nodos (personalizable)
- ✅ Logs de cluster habilitados (API, Audit, Authenticator, etc.)
- ✅ OIDC Provider para IRSA (IAM Roles for Service Accounts)

### IAM Roles
- ✅ EKS Cluster Role
- ✅ EKS Node Role (con permisos para ECR)
- ✅ ALB Controller Role (para Ingress)

## Seguridad

- Los nodos worker se encuentran en subredes privadas
- Acceso a ECR habilitado para los nodos
- Security groups configurados para permitir comunicación intra-cluster
- OIDC habilitado para IRSA (roles seguros para pods)

## Siguientes Pasos

1. **Crear manifiestos Kubernetes** en `/k8s/`
   - Deployments para Frontend y Backend
   - Services y Ingress
   - ConfigMaps para variables de entorno
   - HPA para autoscaling

2. **Instalar ALB Ingress Controller**
   - Permite exponer servicios públicamente con Application Load Balancer

3. **Configurar Pipeline CI/CD** en GitHub Actions
   - Build de imágenes Docker
   - Push a ECR
   - Deploy automático a EKS

## Troubleshooting

### El cluster no aparece con `kubectl get nodes`

```bash
# Verificar que kubeconfig está correcto
aws eks describe-cluster --name devops-u2-eks --region us-east-1

# Reconfigura kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-u2-eks --force
```

### Ver logs del cluster

```bash
# API logs
aws logs tail /aws/eks/devops-u2-eks/cluster --follow

# Ver eventos del cluster
kubectl get events -A
```

### Destruir la infraestructura

```bash
terraform destroy
```

## Costos Estimados

- **EKS Cluster**: $0.10/hora
- **EC2 Nodes (2x t3.medium)**: ~$0.0416 x 2/hora
- **NAT Gateway**: $0.045/hora + $0.045/GB (tráfico procesado)
- **Elastic IP**: $0.005/hora (sin usar)

**Total aproximado**: ~$0.25/hora (sin tráfico NAT)

---

Para más información:
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
