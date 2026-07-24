# ---- Build stage: compile the React app ----
FROM node:20-slim AS build

WORKDIR /app

# Install dependencies first so this layer is cached separately
# from application source changes
COPY package.json ./
RUN npm install

COPY public ./public
COPY src ./src
RUN npm run build

# ---- Runtime stage: serve the static build with Nginx ----
FROM nginx:1.27-alpine

RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/frontend.conf
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:80 >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
