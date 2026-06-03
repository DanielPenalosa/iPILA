# iPILA - Municipal Waste Management System
# Build: 2026-02-05 - Advanced Analytics v1.1.0
# Force rebuild: Analytics enhancement deployed
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependency files first
COPY pubspec.* ./
RUN flutter pub get

# Copy all source files
COPY . .

# Clean and rebuild completely
RUN flutter clean
RUN flutter pub get
RUN flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
