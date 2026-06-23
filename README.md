# Proyecto DevOps — EP3 (EKS + Kubernetes)

## Descripción

Infraestructura y aplicación desplegadas en **AWS EKS** usando **Terraform**, **Kubernetes** y **GitHub Actions**. La arquitectura corre como microservicios en un cluster EKS con imágenes almacenadas en Amazon ECR.

---

## Equipo

| Integrante | Rol principal |
|------------|---------------|
| Aracelly Zenteno | Infraestructura AWS, Kubernetes, CI/CD |
| Matias Jara | Desarrollo backend, Docker, Terraform |

---

## Componentes de la aplicación

| Servicio | Tecnología | Puerto |
|----------|------------|--------|
| Frontend | React + Vite + nginx | 80 |
| Backend Ventas | Spring Boot (Java 17) | 8080 |
| Backend Despachos | Spring Boot (Java 17) | 8081 |
| MySQL 8 | Imagen oficial | 3306 |

---

## Estructura del proyecto

```text
devops-2/
├── .github/workflows/
│   ├── ci.yml          # Build de imágenes Docker (main, develop)
│   └── cd.yml          # Build + push ECR + deploy en EKS (rama deploy)
├── back-Ventas_SpringBoot/
│   └── Springboot-API-REST/            # API ventas + Dockerfile
├── back-Despachos_SpringBoot/
│   └── Springboot-API-REST-DESPACHO/   # API despachos + Dockerfile
├── front_despacho/                     # Frontend React + Dockerfile + nginx
├── infra/
│   ├── etapa_1/        # Infraestructura EP1
│   ├── etapa_2/        # Infraestructura EP2
│   └── etapa_3/        # Terraform EKS (EP3 — activo)
│       ├── main.tf     # Versiones y provider AWS
│       ├── variables.tf
│       ├── locals.tf   # Tags comunes y lista de repos ECR
│       ├── vpc.tf      # VPC, subredes públicas, IGW, route tables
│       ├── security.tf # Security Groups para cluster y nodos
│       ├── eks.tf      # Cluster EKS + Node Group (usa LabRole)
│       ├── ecr.tf      # 3 repositorios ECR con for_each
│       └── outputs.tf
├── k8s/                # Manifiestos de Kubernetes
│   ├── namespace.yml
│   ├── configmap.yml
│   ├── secrets.yml
│   ├── mysql-deployment.yml
│   ├── mysql-service.yml
│   ├── backend-ventas-deployment.yml
│   ├── backend-ventas-service.yml
│   ├── backend-despachos-deployment.yml
│   ├── backend-despachos-service.yml
│   ├── frontend-deployment.yml
│   ├── frontend-service.yml
│   ├── hpa.yml
│   └── .env.example
├── docker-compose.yml  # Entorno local
├── .env.example
└── README.md
```

---

## Requisitos

| Herramienta | Nota |
|-------------|------|
| **Terraform CLI** | >= 1.6.0 |
| **AWS CLI** | Credenciales del AWS Academy Learner Lab |
| **kubectl** | Para interactuar con el cluster EKS |
| **Docker** | Para build local |
| **Provider AWS** | `hashicorp/aws` ~> 5.0 |

---

## Arquitectura del despliegue

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
│                                                             │
│   ┌─────────────────── VPC 10.0.0.0/16 ─────────────────┐  │
│   │                                                       │  │
│   │   Subred pública AZ-1        Subred pública AZ-2     │  │
│   │   10.0.1.0/24                10.0.2.0/24             │  │
│   │         │                          │                  │  │
│   │         └──────────┬───────────────┘                  │  │
│   │                    │                                   │  │
│   │            ┌───────▼────────┐                         │  │
│   │            │  EKS Cluster   │  Kubernetes 1.32        │  │
│   │            │  Node Group    │  SPOT t3.large (1-3)    │  │
│   │            │                │                         │  │
│   │            │  namespace: apps                         │  │
│   │            │  ┌───────────────────────────────────┐   │  │
│   │            │  │ Pod: frontend-despacho (x2)       │   │  │
│   │            │  │ Pod: backend-ventas (x2)          │   │  │
│   │            │  │ Pod: backend-despachos (x2)       │   │  │
│   │            │  │ Pod: mysql (x1)                   │   │  │
│   │            │  └───────────────────────────────────┘   │  │
│   │            └───────┬────────┘                         │  │
│   │                    │                                   │  │
│   └────────────────────┼───────────────────────────────── ┘  │
│                        │                                      │
│   Amazon ECR           │  LoadBalancer (ELB)                  │
│   ┌──────────────┐     │                                      │
│   │ frontend-    │     └──────────────────────────────────┐   │
│   │ despacho     │                                        │   │
│   │ backend-     │◄── GitHub Actions (build & push)       │   │
│   │ ventas       │                                        │   │
│   │ backend-     │                                        │   │
│   │ despachos    │                                        │   │
│   └──────────────┘                                        │   │
└───────────────────────────────────────────────────────────┘   │
                                                                 │
Usuario (Internet) ──────────────────────────────────────────── ┘
```

## Flujo de datos

```
Usuario (Internet)
        │  HTTP :80
        ▼
AWS ELB (frontend-despacho-service — LoadBalancer)
        │
        ▼
Pod Frontend — nginx (namespace: apps)
        │
        ├─ /api/ventas/*    → backend-ventas-service :8080
        └─ /api/despachos/* → backend-despachos-service :8081
                                      │
                                      ▼
                              Pod Backend (Spring Boot)
                                      │  JDBC :3306
                                      ▼
                              Pod MySQL (mysql-service — ClusterIP)

GitHub Actions (rama deploy)
        │
        ├─ build imágenes Docker
        ├─ push a Amazon ECR
        └─ kubectl apply → EKS (namespace: apps)
```

---

## Flujo de uso

### 1. Clona el repositorio

```bash
git clone <url-del-repo>
cd devops-2
```

### 2. Configura credenciales AWS

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

aws sts get-caller-identity
```

### 3. Despliega la infraestructura con Terraform

```bash
cd infra/etapa_3
terraform init
terraform plan
terraform apply
```

Esto crea:
- VPC con 2 subredes públicas
- Security Groups para el cluster y los nodos
- Cluster EKS + Node Group (instancias SPOT `t3.large`)
- 3 repositorios ECR: `frontend-despacho`, `backend-ventas`, `backend-despachos`

### 4. Conecta kubectl al cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-u2-eks
```

### 5. Deploy automático (GitHub Actions)

Hacer push a la rama `deploy` dispara el pipeline completo:

1. Build de las 3 imágenes Docker (`linux/amd64`)
2. Push a ECR con tag `${{ github.sha }}`
3. Reemplaza variables de imagen en los manifiestos con `envsubst`
4. `kubectl apply` de todos los manifiestos en orden
5. Espera rollout de cada deployment
6. Muestra la URL del LoadBalancer del frontend

### 6. Desarrollo local (sin AWS)

```bash
cp .env.example .env
docker compose up --build
```

| Servicio | URL local |
|----------|-----------|
| Frontend | http://localhost:3000 |
| API Ventas | http://localhost:8080 |
| API Despachos | http://localhost:8081 |

---

## CI/CD — GitHub Actions

| Archivo | Trigger | Qué hace |
|---------|---------|----------|
| `ci.yml` | Push / PR a `main` o `develop` | Construye las 3 imágenes para validar que compilan |
| `cd.yml` | Push a `deploy` | Build + push ECR + deploy completo en EKS |

### Variables y Secrets requeridos en GitHub

**Repository Variables** (`Settings → Variables`):

| Variable | Ejemplo |
|----------|---------|
| `AWS_REGION` | `us-east-1` |
| `EKS_CLUSTER_NAME` | `devops-u2-eks` |
| `K8S_NAMESPACE` | `apps` |
| `ECR_FRONTEND_REPOSITORY` | `frontend-despacho` |
| `ECR_VENTAS_REPOSITORY` | `backend-ventas` |
| `ECR_DESPACHOS_REPOSITORY` | `backend-despachos` |

**Repository Secrets** (`Settings → Secrets`):

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Del Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Del lab |
| `AWS_SESSION_TOKEN` | Del lab (sesiones temporales) |

---

## Infraestructura EKS — detalle

| Recurso | Detalle |
|---------|---------|
| **VPC** `10.0.0.0/16` | DNS habilitado |
| **Subredes públicas** | `10.0.1.0/24` y `10.0.2.0/24` en 2 AZs |
| **Internet Gateway** | Acceso a Internet |
| **EKS Cluster** | Kubernetes 1.32, acceso público + privado |
| **Node Group** | SPOT `t3.large`, 1–3 nodos (desired: 2) |
| **IAM** | Usa el `LabRole` existente de AWS Academy |
| **ECR** | 3 repos con `IMMUTABLE` tags y scan on push |

---

## Kubernetes — detalle

Todos los recursos corren en el namespace `apps`.

| Manifiesto | Tipo | Descripción |
|------------|------|-------------|
| `namespace.yml` | Namespace | Namespace `apps` |
| `configmap.yml` | ConfigMap | Variables de conexión a DB |
| `secrets.yml` | Secret | Credenciales MySQL |
| `mysql-*.yml` | Deployment + Service | MySQL 8, ClusterIP |
| `backend-ventas-*.yml` | Deployment + Service | Spring Boot :8080, 2 réplicas, ClusterIP |
| `backend-despachos-*.yml` | Deployment + Service | Spring Boot :8081, 2 réplicas, ClusterIP |
| `frontend-*.yml` | Deployment + Service | nginx :80, 2 réplicas, **LoadBalancer** |
| `hpa.yml` | HPA | Autoscaling por CPU (50–60%) en los 3 servicios |

---

## Buenas prácticas incluidas

- **Terraform modularizado** por etapas; `etapa_3` es completamente independiente.
- **`LabRole` reutilizado** — no se crean roles IAM propios, compatible con AWS Academy.
- **ECR con tags inmutables** — evita sobreescribir imágenes ya desplegadas.
- **`envsubst`** en el pipeline para inyectar las URLs de imagen en los manifiestos sin modificar los archivos fuente.
- **HPA** configurado en los 3 servicios para escalar automáticamente bajo carga.
- **Dockerfiles multi-stage** con usuario no root en todos los servicios.
- **Health checks** en los backends; MySQL espera estar listo antes de que arranquen
