# --- ビルドステージ ---
FROM --platform=linux/amd64 maven:3.9.7-eclipse-temurin-17 AS build
WORKDIR /build
COPY app/pom.xml .
COPY app/src ./src
RUN mvn clean package -DskipTests

# --- 実行ステージ ---
FROM --platform=linux/amd64 amazoncorretto:17-alpine
WORKDIR /app
COPY --from=build /build/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
