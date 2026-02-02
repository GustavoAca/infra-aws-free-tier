FROM nginx:1.25-alpine

# Remove config default
RUN rm /etc/nginx/conf.d/default.conf

# Copia config customizado
COPY nginx.conf /etc/nginx/nginx.conf

# Expondo porta (documental)
EXPOSE 80

# Healthcheck local (opcional, mas recomendado)
HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget -qO- http://localhost/health || exit 1
