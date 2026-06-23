# Infra - Etapa 3: EKS Cluster Infrastructure

Este directorio contiene la configuración de Terraform para crear un cluster EKS en AWS. Los manifiestos de Kubernetes se encuentran en la carpeta `k8s/`.

## Arquitectura

- **AWS EKS** cluster con nodos gestionados
- **VPC** con subredes públicas (ALB) y privadas (worker nodes)
- **Roles IAM** para EKS, worker nodes, ALB Controller e IRSA
- **ECR repositories** para Frontend y Backend
- Logs habilitados en CloudWatch

## Estructura de Archivos

**En `infra/etapa_3/`:**
- `main.tf` - Provider AWS
- `variables.tf` - Variables de AWS y EKS
- `outputs.tf` - Outputs del cluster, VPC, ECR
- `vpc.tf` - VPC, subredes, Internet Gateway, NAT, Security Groups
- `iam.tf` - Roles IAM para EKS y nodes
- `eks.tf` - Cluster EKS y node groups
- `ecr.tf` - Repositories ECR para Frontend y Backend

**En `k8s/` (Kubernetes manifiestos):**
- `main.tf` - Providers de Kubernetes y Helm
- `variables.tf` - Variables para deployments
- `outputs.tf` - Outputs de servicios y ALB
- `deployments.tf` - Frontend y Backend deployments
- `services.tf` - Services y ALB Ingress
- `autoscaling.tf` - HPA (Horizontal Pod Autoscaler)
- `secrets.tf` - Secrets para DB y ECR

## Prerequisitos

- AWS credentials configuradas
- Terraform >= 1.0
- kubectl instalado
- aws CLI configurado

## Uso

```powershell
# 1. Desplegar infraestructura EKS
cd infra/etapa_3
terraform init
terraform plan
terraform apply

# 2. Configurar kubectl
terraform output configure_kubectl  # Copiar y ejecutar el comando

# 3. Desplegar servicios de Kubernetes
cd ../../k8s
terraform init
terraform plan -var-file=../infra/etapa_3/terraform.tfvars
terraform apply
```

## Notas

- Guarda outputs de `etapa_3` para usar como variables en `k8s/`
- El ALB DNS aparecerá 2-3 minutos después de aplicar
- Ver [k8s/README.md](../../k8s/README.md) para detalles de deployments
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
