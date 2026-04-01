# --- Étape de Build Frontend ---
FROM node:20-alpine as front-build
WORKDIR /src
COPY ./front/package*.json ./
RUN npm ci
COPY ./front .
RUN npx @angular/cli build --configuration production

# --- Étape de Build Backend ---
FROM gradle:8-jdk17-alpine as back-build
WORKDIR /src
COPY ./back .
RUN ./gradlew build -x test

# --- Image Finale FRONTEND (Scaling indépendant) ---
FROM nginx:alpine as frontend
COPY --from=front-build /src/dist/microcrm/browser /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# --- Image Finale BACKEND (Scaling indépendant) ---
FROM eclipse-temurin:17-jre-alpine as backend
WORKDIR /app
COPY --from=back-build /src/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]