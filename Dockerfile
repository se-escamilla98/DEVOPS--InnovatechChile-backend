# =========================================
# ETAPA 1: "builder" — instala dependencias
# =========================================
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# =========================================
# ETAPA 2: "production" — imagen final minimalista
# Solo lleva node_modules, el código fuente y package.json.
# Corre como usuario NO-root por seguridad (mínimo privilegio).
# =========================================
FROM node:24-alpine AS production
WORKDIR /app

# Crea un grupo y un usuario sin privilegios.
# Alpine usa addgroup/adduser (no useradd).
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copia solo lo necesario desde la etapa builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/package.json ./

# Cambia la propiedad de los archivos al usuario no-root
RUN chown -R appuser:appgroup /app

# A partir de aquí el contenedor corre como appuser, no como root
USER appuser

EXPOSE 8080
CMD ["node", "src/index.js"]