# ============================================================
# STAGE 1: Build — Compilar el proyecto Java con Maven
# ============================================================
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /build

# Copiar el pom.xml primero para aprovechar la caché de dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar el código fuente y compilar (sin ejecutar tests)
COPY src ./src
RUN mvn clean package -DskipTests -B

# ============================================================
# STAGE 2: Runtime — Ejecutar el .jar con JRE mínimo
# ============================================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copiar solo el .jar generado en Stage 1
COPY --from=builder /build/target/*.jar app.jar

# Usuario no-root para mínimo privilegio
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
