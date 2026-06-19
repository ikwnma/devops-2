# k8s/ - Kubernetes Manifiestos

Este directorio contiene la configuración de Terraform para desplegar Frontend y Backend en EKS.

## Archivos

- `main.tf` - Providers de Kubernetes y Helm
- `variables.tf` - Variables para deployments, escalado, DB
- `outputs.tf` - Outputs de servicios, ALB, HPA
- `deployments.tf` - Deployments de Frontend y Backend
- `services.tf` - Services, ALB Ingress Controller
- `autoscaling.tf` - HPA y Metrics Server
- `secrets.tf` - Secrets para DB y ECR

## Prerequisitos

- EKS cluster ya creado (desde `infra/etapa_3/`)
- Outputs de `etapa_3` disponibles

## Estructura de Deployments

**Frontend:**
- Imagen: ECR
- Port: 3000
- Replicas: 2-4 (HPA)
- CPU: 100m-200m
- Memory: 256Mi-512Mi

**Backend:**
- Imagen: ECR
- Port: 8080
- Replicas: 2-5 (HPA)
- CPU: 250m-500m
- Memory: 512Mi-1Gi
- Variables: SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD

## Uso

```powershell
# Crear archivo terraform.tfvars
$content = @"
aws_region                     = "us-east-1"
eks_cluster_name              = "devops-u2-eks"
eks_cluster_endpoint          = "https://xxx.eks.us-east-1.amazonaws.com"
eks_cluster_ca_certificate    = "LS0tLS..."
project_name                  = "devops-u2"
db_username                   = "admin"
db_password                   = "SecurePassword123"
alb_controller_role_arn       = "arn:aws:iam::123456789:role/..."
ecr_registry_id               = "123456789"
"@
$content | Out-File terraform.tfvars

# Desplegar
terraform init
terraform plan
terraform apply
```

## Verificar Despliegue

```powershell
# Ver pods
kubectl get pods -n apps

# Ver services
kubectl get svc -n apps

# Ver HPA
kubectl get hpa -n apps

# Ver ALB URL
kubectl get ingress -n apps
```

## Integración con CI/CD

El pipeline debe:
1. Hacer build de imágenes Docker
2. Push a ECR con tags
3. Actualizar Deployments con nuevas imágenes (ej. `DEPLOYMENT_IMAGE=xxx:v1.2.3`)
