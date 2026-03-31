# ── Fase 1: build do JAR com Maven ──────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /build

# Copia só o pom.xml primeiro (optimização de cache)
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copia o código fonte e faz o build
COPY src ./src
RUN mvn clean package -DskipTests -q

# ── Fase 2: imagem final leve ────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copia apenas o JAR da fase de build
COPY --from=build /build/target/versao1-0.0.1-SNAPSHOT.jar app.jar
COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]