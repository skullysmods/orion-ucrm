# --- BUILD FRONTEND ---
FROM node:20-alpine as front-build
WORKDIR /src
COPY ./front/package*.json ./
RUN npm ci
COPY ./front .
RUN npx @angular/cli build --configuration production

# --- BUILD BACKEND ---
FROM gradle:8-jdk17-alpine as back-build
WORKDIR /src
COPY ./back .
RUN ./gradlew build -x test

# --- IMAGE FINALE FRONTEND (Nginx pour la haute disponibilité) ---
FROM nginx:alpine as frontend
RUN apk update && apk upgrade --no-cache
COPY --from=front-build /src/dist/microcrm/browser /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# --- IMAGE FINALE BACKEND (JRE Temurin optimisée et sécurisée) ---
FROM eclipse-temurin:17-jre-alpine as backend
WORKDIR /app
RUN apk update && apk upgrade --no-cache
COPY --from=back-build /src/build/libs/*.jar app.jar
EXPOSE 8080
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
ENTRYPOINT ["java", "-jar", "app.jar"]