# Innovatech Chile — Backend

API REST desarrollada con Node.js y Express, containerizada con Docker y desplegada automáticamente en AWS EC2 mediante GitHub Actions.

## Tecnologías utilizadas

- Node.js 24 + Express
- PostgreSQL 15
- Docker + Docker Compose
- GitHub Actions (CI/CD)
- AWS EC2

## Arquitectura

El backend corre en una subred privada de AWS, solo accesible desde el Frontend mediante el puerto 8080. La base de datos PostgreSQL corre en el mismo stack de Docker Compose, conectada mediante una red interna sin exponer puertos al exterior.

```
Frontend (subred pública) → Backend:8080 (subred privada) → PostgreSQL:5432 (red interna Docker)
```

## Estructura del proyecto

```
backend/
├── src/
│   └── index.js          # Servidor Express principal
├── Dockerfile            # Multi-stage build con usuario no root
├── docker-compose.yml    # Stack completo con PostgreSQL
├── .dockerignore         # Excluye node_modules y .env
├── .env                  # Variables de entorno locales (no se sube a GitHub)
└── .github/
    └── workflows/
        └── deploy.yml    # Pipeline CI/CD
```

## Variables de entorno

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `DB_HOST` | Host de PostgreSQL | `db` |
| `DB_PORT` | Puerto de PostgreSQL | `5432` |
| `DB_NAME` | Nombre de la base de datos | `innovatech_db` |
| `DB_USER` | Usuario de PostgreSQL | `innovatech_user` |
| `DB_PASSWORD` | Contraseña de PostgreSQL | `innovatech_pass` |
| `PORT` | Puerto del servidor | `8080` |

## Cómo correr el proyecto localmente

### Requisitos previos
- Docker Desktop instalado
- Git

### Pasos

1. Clona el repositorio:
```bash
git clone https://github.com/se-escamilla98/DEVOPS--InnovatechChile-backend.git
cd DEVOPS--InnovatechChile-backend
```

2. Crea el archivo de variables de entorno:
```bash
cp .env.example .env
```

3. Levanta los contenedores:
```bash
docker compose up --build
```

4. Verifica que el servidor está corriendo:
```
http://localhost:8080/health
```

## Endpoints disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Verifica que el servidor está vivo |
| GET | `/api/productos` | Retorna todos los productos |
| POST | `/api/productos` | Crea un producto nuevo |

### Ejemplo de uso

Crear un producto:
```bash
curl -X POST http://localhost:8080/api/productos \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Laptop", "precio": 999.99}'
```

## Pipeline CI/CD

El pipeline se activa automáticamente con cada push a la rama `deploy`.

```
push a rama deploy
        ↓
GitHub Actions (ubuntu-latest)
        ↓
Checkout código
        ↓
Login en Docker Hub
        ↓
Build imagen Docker (multi-stage)
        ↓
Push imagen → seescamilla/innovatech-backend:latest
        ↓
SSH a EC2 → docker pull → docker compose up -d
```

### Secrets requeridos en GitHub

| Secret | Descripción |
|--------|-------------|
| `DOCKER_USERNAME` | Usuario de Docker Hub |
| `DOCKER_PASSWORD` | Access token de Docker Hub |
| `EC2_HOST` | IP pública de la instancia EC2 |
| `EC2_USER` | Usuario SSH de EC2 |
| `EC2_KEY` | Llave privada SSH |

## Decisiones técnicas

**¿Por qué multi-stage build?**
Reduce el tamaño de la imagen final eliminando herramientas de desarrollo innecesarias en producción, mejorando la seguridad y el rendimiento.

**¿Por qué usuario no root?**
Si alguien compromete el contenedor, no tendrá privilegios de administrador sobre el sistema host. Es una práctica de mínimo privilegio.

**¿Por qué named volume en lugar de bind mount?**
Los named volumes son gestionados por Docker y son independientes del sistema operativo del host, lo que los hace portables entre Windows, Linux y Mac. En EC2 garantizan que los datos de PostgreSQL persisten aunque el contenedor se destruya y recree.

**¿Por qué rama deploy como trigger?**
Permite trabajar libremente en la rama main sin disparar despliegues accidentales. Solo cuando el código está revisado y listo se hace merge o push a deploy.