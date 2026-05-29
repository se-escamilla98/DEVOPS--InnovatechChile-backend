# =========================================
# ETAPA 1: "builder" - instala TODO
# Esta etapa existe solo para preparar las dependencias.
# No llegará a la imagen final, es desechable.
# =========================================
FROM node:24-alpine AS builder

# Establecemos el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos PRIMERO solo los archivos de dependencias.
# ¿Por qué primero? Porque Docker cachea cada instrucción como una capa.
# Si el código cambia pero package.json no, Docker reutiliza la capa
# de npm install sin reinstalar todo. Esto acelera enormemente los builds.
COPY package*.json ./

# Instalamos TODAS las dependencias (incluyendo devDependencies)
RUN npm ci

# Ahora sí copiamos el resto del código fuente
COPY . .

# =========================================
# ETAPA 2: "production" - imagen final limpia
# Solo copiamos lo estrictamente necesario desde la etapa anterior.
# =========================================
FROM node:24-alpine AS production

# Buena práctica de seguridad: creamos un usuario sin privilegios.
# Por defecto Docker corre como root, lo que es un riesgo de seguridad.
# Si alguien compromete el contenedor, no tendrá acceso root al host.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiamos solo las dependencias de producción desde la etapa builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/package.json ./

# Cambiamos al usuario sin privilegios (mínimo privilegio)
USER appuser

# Documentamos el puerto que usa la aplicación.
# EXPOSE no abre el puerto por sí solo, es documentación para Docker Compose.
EXPOSE 8080

# El comando que se ejecuta cuando el contenedor arranca
CMD ["node", "src/index.js"]