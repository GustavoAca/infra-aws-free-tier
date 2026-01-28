#!/bin/bash

IMAGE=$1

if [ -z "$IMAGE" ]; then
  echo "Uso: ./rollback.sh gacacio/users-service:1.3.1"
  exit 1
fi

echo "⛔ Parando container atual..."
docker stop users-service || true
docker rm users-service || true

echo "⬇️ Pull da imagem $IMAGE"
docker pull $IMAGE

echo "🚀 Subindo rollback..."
docker run -d \
  --name users-service \
  -p 8081:8081 \
  $IMAGE

echo "✅ Rollback concluído"
