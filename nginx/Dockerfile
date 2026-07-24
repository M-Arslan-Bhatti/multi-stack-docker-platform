# Lightweight Nginx image serving two static sites on two ports
FROM nginx:1.27-alpine

# Remove default config and install our two-server-block config
RUN rm -f /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/multisite.conf
COPY html/site1 /usr/share/nginx/html/site1
COPY html/site2 /usr/share/nginx/html/site2

EXPOSE 81 82

HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:81 >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
