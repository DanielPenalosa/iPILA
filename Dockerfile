# iPILA - Municipal Waste Management System
# Build: 2026-02-05 - User management fixes
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
