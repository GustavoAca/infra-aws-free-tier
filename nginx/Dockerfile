FROM nginx:1.25-alpine

# Remove config default interna
RUN rm /etc/nginx/conf.d/default.conf

# Copia base nginx.conf (somente base, sem upstream/server)
COPY nginx.conf /etc/nginx/nginx.conf

# Copia default.conf com upstream e server block
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget -qO- http://localhost/health || exit 1