# Innovatech Chile — Backend

API REST con Node.js + Express + PostgreSQL desplegada en AWS ECS Fargate como parte del EP3 de ISY1101 (Introducción a Herramientas DevOps, DuocUC 2025).

## Stack tecnológico

- **Runtime**: Node.js 24 (Alpine)
- **Framework**: Express.js
- **Base de datos**: PostgreSQL 15
- **Contenedor**: Docker (multi-stage build)
- **Orquestación**: AWS ECS + Fargate
- **Registro de imágenes**: Amazon ECR
- **CI/CD**: GitHub Actions
- **Secrets**: AWS Secrets Manager
- **Logs**: Amazon CloudWatch

## Arquitectura en producción

```
ALB Interno (:8080)
    ↓
Fargate Task (SG_BACK — subred privada 10.0.2.0/24)
    ├── Contenedor: backend (Node.js :8080)
    └── Contenedor: postgres (PostgreSQL :5432)
              ↑ comunicación por localhost (misma task)
```

El backend **nunca tiene IP pública**. Solo es accesible a través del ALB interno desde dentro de la VPC.

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/health` | Health check — devuelve `{ status: "ok" }` |
| GET | `/api/productos` | Lista todos los productos |
| POST | `/api/productos` | Crea un producto nuevo |

## Variables de entorno

En **desarrollo local** (archivo `.env`):

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=innovatech
DB_USER=innovatech_user
DB_PASSWORD=tu_password_local
```

En **producción** (AWS ECS), las variables `DB_USER` y `DB_PASSWORD` se inyectan desde **AWS Secrets Manager** (`innovatech/db-credentials`) usando el ARN en la Task Definition. Nunca aparecen en texto plano en el código ni en la consola de AWS.

## Ejecución local

```bash
# Clonar el repositorio
git clone https://github.com/se-escamilla98/DEVOPS--InnovatechChile-backend.git
cd DEVOPS--InnovatechChile-backend

# Copiar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales locales

# Levantar con Docker Compose
docker compose up -d

# Verificar que el backend responde
curl http://localhost:8080/health
```

## Build de la imagen Docker

```bash
docker build -t innovatech-backend:latest .
```

El Dockerfile usa **multi-stage build**:
- Stage `builder`: instala dependencias con `npm ci`
- Stage `production`: copia solo lo necesario, corre como usuario no-root (`appuser`)

## Pipeline CI/CD (GitHub Actions)

Se activa automáticamente con cada `push` a la rama `deploy`.

### Pasos del pipeline

| Paso | Acción | Descripción |
|------|--------|-------------|
| 1 | `actions/checkout@v4` | Descarga el código |
| 2 | `configure-aws-credentials@v4` | Configura credenciales AWS (Key + Secret + Session Token) |
| 3 | `amazon-ecr-login@v2` | Login en Amazon ECR con token temporal |
| 4 | `docker build + push` | Build con `--no-cache`, tag con SHA del commit + latest |
| 5 | `aws ecs update-service` | Rolling deploy en ECS sin downtime |

### Secrets requeridos en GitHub

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Clave de acceso del Learner Lab |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta del Learner Lab |
| `AWS_SESSION_TOKEN` | Token de sesión (se renueva con cada sesión del Lab) |
| `AWS_ACCOUNT_ID` | `234744815650` |
| `AWS_REGION` | `us-east-1` |

> ⚠️ Los tres primeros secrets son temporales y deben actualizarse cada vez que se reinicia el Learner Lab.

## Despliegue en AWS ECS

### Recursos desplegados

| Recurso | Valor |
|---------|-------|
| Clúster | `innovatech-cluster` |
| Servicio | `backend-service` |
| Task Definition | `innovatech-backend:3` |
| Imagen ECR | `234744815650.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend:latest` |
| Subred | Privada (`subnet-08c9bc700f9657ba5`) |
| Security Group | `SG_BACK` (sg-074594ce3cc6e5779) |
| ALB interno | `innovatech-alb-backend` (`:8080`) |
| Target Group | `innovatech-tg-backend` (health check: `/health`) |

### Autoscaling

- **Tipo**: Target Tracking
- **Métrica**: `ECSServiceAverageCPUUtilization`
- **Umbral**: 50% CPU
- **Mínimo**: 1 tarea | **Máximo**: 3 tareas
- **ScaleOut cooldown**: 60 segundos
- **ScaleIn cooldown**: 120 segundos

### Logs

Los logs se envían automáticamente a CloudWatch:
- **Log Group**: `/ecs/innovatech-backend`
- **Streams**: `backend/<task-id>` y `postgres/<task-id>`

## Autores

- **Sebastián Escamilla** — se.escamilla@duocuc.cl
- **Livan Sepúlveda**

DuocUC — Analista Programador — ISY1101 Introducción a Herramientas DevOps — 2025
