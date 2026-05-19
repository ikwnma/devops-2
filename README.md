# Terraform AWS Infrastructure — Proyecto DevOps (EP2)

## Descripción

Infraestructura y aplicación gestionadas con **Terraform** y **Docker** para desplegar una arquitectura de microservicios en **AWS**, alineada con la evaluación EP2 (Innovatech Chile).

Características principales:

- **VPC** con subred pública y subred privada.
- **EC2 frontend** (React + nginx) como único punto de acceso desde Internet.
- **EC2 backend** (Spring Boot: ventas y despachos) en subred privada.
- **EC2 MySQL** con volumen Docker para persistencia de datos.
- **NAT Gateway** para que las instancias privadas descarguen imágenes desde ECR.
- **Repositorios ECR** para las imágenes de contenedores.
- **GitHub Actions**: CI en `main`/`develop` y CD en rama `deploy`.

Solo el **frontend** es accesible desde Internet. El tráfico hacia los backends pasa por el proxy nginx del frontend usando IPs privadas dentro de la VPC.

---

## Equipo

| Integrante | Rol principal | Contacto |
|------------|---------------|----------|
| Felipe Ardiles | Infraestructura AWS, Docker, CI/CD, Terraform | Repositorio principal |
| Renato Herrera | Desarrollo backend, apoyo en despliegue y documentación | idkraes17@gmail.com |

Los commits del proyecto EP2 incluyen coautoría de **Renato Herrera** (`Co-authored-by`) cuando corresponde a trabajo en pareja.

---

## Componentes de la aplicación

| Servicio | Tecnología | Despliegue |
|----------|------------|------------|
| Frontend | React + Vite + nginx (sin root) | EC2 pública — puerto 80 |
| Backend Ventas | Spring Boot (Java 17) | EC2 privada — puerto 8080 |
| Backend Despachos | Spring Boot (Java 17) | EC2 privada — puerto 8081 |
| MySQL 8 | Docker + volumen `mysql_data` | EC2 privada — puerto 3306 |

---

## Estructura del proyecto

```text
devops-2/
├── .github/workflows/
│   ├── ci.yml                    # Build de imágenes (main, develop)
│   ├── cd.yml                    # Build + ECR + deploy EC2 (rama deploy)
│   └── deploy.yml                # Pipeline alternativo con Docker Hub + bastión
├── back-Ventas_SpringBoot/
│   └── Springboot-API-REST/      # API ventas + Dockerfile
├── back-Despachos_SpringBoot/
│   └── Springboot-API-REST-DESPACHO/  # API despachos + Dockerfile
├── front_despacho/               # Frontend React + Dockerfile + nginx template
├── infra/
│   ├── etapa_1/                  # Registro ECR (3 repositorios)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── etapa_2/                  # VPC, EC2, Security Groups, NAT
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── templates/            # user_data — bootstrap de cada EC2
│           ├── mysql_user_data.sh
│           ├── backend_user_data.sh
│           └── frontend_user_data.sh
├── scripts/
│   ├── deploy-evaluacion.sh      # Automatización local completa
│   └── deploy.env.example        # Variables de entorno de ejemplo
├── docker-compose.yml            # Entorno local completo
├── .env.example
└── README.md
```

---

## Requisitos

| Herramienta | Versión / nota |
|-------------|----------------|
| **Terraform CLI** | >= 1.0 |
| **AWS CLI** | Credenciales del AWS Academy Learner Lab |
| **Docker** | Para build local y push a ECR |
| **Git** | Control de versiones |
| **Provider AWS** | `hashicorp/aws` ~> 5.0 |
| **Key pair** | `vockey` (Download PEM del lab → `~/.ssh/vockey.pem`) |

Permisos necesarios en la cuenta del lab: creación de VPC, EC2, ECR, IAM (rol `LabRole`).

---

## Flujo de datos

```
Usuario (Internet)
        │  HTTP :80
        ▼
EC2 Frontend — nginx (subred pública 10.0.1.0/24)
        │  proxy /api/* → IP privada
        ▼
EC2 Backend — Spring Boot (subred privada 10.0.2.0/24)
   :8080 Ventas  /  :8081 Despachos
        │  JDBC :3306
        ▼
EC2 MySQL — Docker + volumen persistente (subred privada)
        
        ▲  docker pull (vía NAT Gateway)
        │
Amazon ECR ← GitHub Actions (build & push)
        │
        └──► SSH deploy → EC2 Frontend (bastión) → EC2 Backend
```

El **NAT Gateway** permite que las instancias privadas salgan a Internet exclusivamente para descargar imágenes desde ECR; ningún tráfico entrante externo llega directo a backend o MySQL.

---

## Flujo de uso

### 1. Clona el repositorio

```bash
git clone https://github.com/FelipeArdiles/devops-ev2.git
cd devops-ev2
```

### 2. Configura credenciales AWS

```bash
aws configure
# O exporta las variables del panel del Learner Lab:
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

aws sts get-caller-identity   # Verifica que las credenciales son válidas
```

### 3. Inicializa y despliega la infraestructura (Terraform)

**Etapa 1 — ECR (crea los 3 repositorios de imágenes):**

```bash
cd infra/etapa_1
terraform init
terraform plan
terraform apply
```

**Etapa 2 — VPC + EC2 + Security Groups + NAT:**

```bash
cd ../etapa_2
terraform init
terraform plan \
  -var="db_password=root" \
  -var="db_name=proyecto_db" \
  -var="key_pair_name=vockey"
terraform apply \
  -var="db_password=root" \
  -var="db_name=proyecto_db" \
  -var="key_pair_name=vockey"
```

### 4. Obtén las IPs de salida

```bash
terraform output frontend_public_ip    # IP pública del frontend (URL de la app)
terraform output backend_private_ip    # IP privada del backend (para secrets / proxy)
terraform output frontend_url
```

### 5. Build y push de imágenes a ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Backend ventas
docker build --platform linux/amd64 \
  -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-u2-backend-ventas:latest \
  ./back-Ventas_SpringBoot/Springboot-API-REST
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-u2-backend-ventas:latest

# Backend despachos
docker build --platform linux/amd64 \
  -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-u2-backend-despachos:latest \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-u2-backend-despachos:latest

# Frontend
docker build --platform linux/amd64 \
  -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-u2-frontend:latest \
  ./front_despacho
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devops-u2-frontend:latest
```

### 6. Despliegue en las EC2 (SSH)

En cada instancia el `user_data` de Terraform crea `/opt/app/deploy.sh`. Para ejecutarlo manualmente:

```bash
# Backend (vía bastión — el frontend actúa como host puente)
ssh -i ~/.ssh/vockey.pem \
  -o ProxyCommand="ssh -i ~/.ssh/vockey.pem -W %h:%p ec2-user@<IP_FRONTEND>" \
  ec2-user@<IP_BACKEND_PRIVADA> 'sudo /opt/app/deploy.sh'

# Frontend (actualiza la IP del backend antes de desplegar)
ssh -i ~/.ssh/vockey.pem ec2-user@<IP_FRONTEND> \
  'sudo sed -i "s/^BACKEND_HOST=.*/BACKEND_HOST=<IP_BACKEND_PRIVADA>/" /opt/app/.env && \
   sudo sed -i "s/^BACKEND_HOST_DESPACHOS=.*/BACKEND_HOST_DESPACHOS=<IP_BACKEND_PRIVADA>/" /opt/app/.env && \
   sudo /opt/app/deploy.sh'
```

**Alternativa con script local:**

```bash
cp scripts/deploy.env.example scripts/deploy.env
# Edita scripts/deploy.env con tus IPs y credenciales
chmod +x scripts/deploy-evaluacion.sh

./scripts/deploy-evaluacion.sh deploy    # Flujo completo (Terraform + build + deploy)
./scripts/deploy-evaluacion.sh redeploy  # Solo SSH (imágenes ya en ECR)
./scripts/deploy-evaluacion.sh destroy   # Destruir toda la infra AWS
```

### 7. Desarrollo local (sin AWS)

```bash
cp .env.example .env
docker compose up --build
```

| Servicio | URL local |
|----------|-----------|
| Frontend | http://localhost:3000 |
| API Ventas | http://localhost:8080 |
| API Despachos | http://localhost:8081 |

El `docker-compose.yml` levanta los 4 servicios (MySQL, backend-ventas, backend-despachos, frontend) en la red interna `app-network`. MySQL expone healthcheck; los backends esperan que esté listo antes de arrancar.

---

## ¿Qué despliega este proyecto?

### Etapa 1 — `infra/etapa_1` (registro de imágenes)

Crea tres repositorios en Amazon ECR con `force_delete = true`:

- `devops-u2-backend-ventas`
- `devops-u2-backend-despachos`
- `devops-u2-frontend`

### Etapa 2 — `infra/etapa_2` (red y cómputo)

| Recurso | Detalle |
|---------|---------|
| **VPC** `10.0.0.0/16` | Red virtual del proyecto, DNS habilitado |
| **Subred pública** `10.0.1.0/24` | EC2 frontend + Internet Gateway |
| **Subred privada** `10.0.2.0/24` | EC2 backend + EC2 MySQL |
| **Internet Gateway** | Entrada/salida de la subred pública |
| **NAT Gateway** | Salida a Internet para subred privada (pull ECR) |
| **Security Groups** | Puerto 80/22 públicos solo en frontend; backends aceptan tráfico únicamente desde el frontend |
| **EC2 frontend** | Contenedor nginx + React — proxy `/api/*` al backend privado |
| **EC2 backend** | Contenedores Spring Boot en :8080 (ventas) y :8081 (despachos) |
| **EC2 MySQL** | Contenedor MySQL con volumen persistente `mysql_data` |

Los `outputs` de Terraform exponen IPs, URLs públicas y URLs de ECR para integrar con CI/CD.

---

## CI/CD — GitHub Actions

### Workflows disponibles

| Archivo | Trigger | Qué hace |
|---------|---------|----------|
| `ci.yml` | Push / PR a `main` o `develop` | Construye las 3 imágenes Docker para validar que compilan |
| `cd.yml` | Push a `deploy` | Build + push a ECR + deploy SSH a EC2 |
| `deploy.yml` | Push a `feature/prueba-deploy` | Pipeline alternativo con Docker Hub como registro |

### Flujo de `cd.yml` paso a paso

1. Checkout del código.
2. Configura credenciales AWS con los secrets del repositorio.
3. Login en ECR.
4. Build y push de las 3 imágenes (`--platform linux/amd64`) a ECR.
5. Configura el agente SSH con la clave privada `EC2_SSH_PRIVATE_KEY`.
6. Despliega el backend vía SSH usando el frontend como bastión.
7. Actualiza las variables `BACKEND_HOST` en el `.env` del frontend y despliega.
8. Verifica que el frontend responde en HTTP (hasta 30 intentos, cada 10 s).

### Ramas y sus roles

| Rama | Propósito | Workflow activo |
|------|-----------|----------------|
| `main` | Integración principal | `ci.yml` — solo build |
| `develop` | Desarrollo activo | `ci.yml` — solo build |
| `deploy` | Producción en AWS | `cd.yml` — build + ECR + deploy |

Para promover a producción:

```bash
git checkout deploy
git merge main
git push origin deploy
```

### Secrets de GitHub Actions

Configurar en **Settings → Secrets and variables → Actions**:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Del Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Del lab |
| `AWS_SESSION_TOKEN` | Del lab (sesiones temporales) |
| `AWS_ACCOUNT_ID` | ID de cuenta AWS |
| `EC2_SSH_PRIVATE_KEY` | Contenido completo de `~/.ssh/vockey.pem` |
| `EC2_FRONTEND_HOST` | Valor de `terraform output frontend_public_ip` |
| `EC2_BACKEND_PRIVATE_IP` | Valor de `terraform output backend_private_ip` |

> Tras cada `terraform apply` que cambie IPs, actualiza los secrets `EC2_FRONTEND_HOST` y `EC2_BACKEND_PRIVATE_IP`.

---

## Infraestructura de red — detalle

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Subred pública 10.0.1.0/24
    └─ EC2 Frontend (nginx :80)
         │  Security Group: 80 público, 22 público
         │
         ├─ Proxy /api/ventas/*    ─────────────────────┐
         └─ Proxy /api/despachos/* ─────────────────────┤
                                                         ▼
                                          Subred privada 10.0.2.0/24
                                              └─ EC2 Backend
                                                   :8080 ventas
                                                   :8081 despachos
                                                   │  Security Group: solo desde frontend
                                                   │
                                                   ▼
                                              EC2 MySQL :3306
                                                   Security Group: solo desde backend
                                                   
Subred privada → NAT Gateway → Internet Gateway → ECR (docker pull)
```

---

## Mejores prácticas incluidas

- **Variables** centralizadas en `infra/etapa_2/variables.tf`; ningún valor sensible hardcodeado en el código fuente.
- **Outputs** de Terraform para IPs, URL del frontend y URIs de ECR.
- **Separación por etapas**: etapa_1 (ECR) y etapa_2 (red + cómputo) permiten gestionar el ciclo de vida independientemente.
- **Plantillas `user_data`** para bootstrap reproducible y declarativo de cada EC2 al arrancar.
- **Security Groups** con principio de mínimo privilegio: solo el frontend tiene exposición pública.
- **Dockerfiles multi-stage** con usuario no root en todos los servicios.
- **Healthcheck** en MySQL; los backends esperan que la base de datos esté lista antes de arrancar (tanto en local como en EC2).
- **`.gitignore`** cubre `.env`, `*.pem`, `terraform.tfstate` y archivos de sistema.
- **CI/CD con ramas diferenciadas**: `main`/`develop` solo validan el build; `deploy` gatilla el despliegue real.

---

## Cómo extender este proyecto

- Añadir **Application Load Balancer** delante del frontend para eliminar la IP pública directa.
- Migrar **MySQL a RDS** para obtener backups automáticos y alta disponibilidad.
- Mover el estado de Terraform a un **backend remoto** (S3 + DynamoDB lock) para trabajo en equipo.
- Agregar **CloudWatch** alarms y logs centralizados para observabilidad.
- Integrar validaciones de infraestructura con `terraform fmt` y `tflint` en el pipeline CI.
- Automatizar rotación de credenciales con **AWS Secrets Manager**.

---

## Cumplimiento EP2 (referencia rápida)

| Requisito | Implementado en |
|-----------|----------------|
| Multi-stage Dockerfiles y usuario no root | `*/Dockerfile` |
| `docker-compose` local con redes y volúmenes | `docker-compose.yml` |
| Frontend en EC2 pública; backends y MySQL en subred privada | `infra/etapa_2/main.tf` |
| Persistencia MySQL con volumen Docker | `docker-compose.yml` + `mysql_user_data.sh` |
| Pipeline build → ECR → deploy EC2 | `.github/workflows/cd.yml` |
| Solo el frontend accesible desde Internet | Security Groups en `infra/etapa_2/main.tf` |
| Repositorios ECR por servicio | `infra/etapa_1/main.tf` |
| NAT Gateway para acceso privado a ECR | `infra/etapa_2/main.tf` |
