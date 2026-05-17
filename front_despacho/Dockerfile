# ============================================================
# STAGE 1: Build — Compilar el proyecto React con npm
# ============================================================
FROM node:22-alpine AS builder

WORKDIR /app

# Copiar archivos de dependencias primero (mejor uso de caché de Docker)
COPY package.json ./

# Instalar dependencias de forma limpia y segura
RUN npm install

# Copiar el resto del código fuente
COPY . .

# Compilar la app para producción
RUN npm run build

# ============================================================
# STAGE 2: Servidor — Servir con Nginx
# ============================================================
FROM nginx:alpine

# Copiar el build generado en Stage 1
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar la configuración personalizada de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Asegurar permisos correctos (mínimo privilegio)
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]