# ============================================================
# STAGE 1: Build — Compilar el proyecto React con pnpm
# ============================================================
FROM node:18-alpine AS builder

WORKDIR /app

# Activar pnpm via corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copiar archivos de dependencias primero (mejor uso de caché de Docker)
COPY package.json pnpm-lock.yaml* ./

# Instalar dependencias
RUN pnpm install --frozen-lockfile

# Copiar el resto del código fuente
COPY . .

# Compilar la app para producción
RUN pnpm run build

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