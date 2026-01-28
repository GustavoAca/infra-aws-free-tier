#!/bin/bash
set -e

AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
SERVICE_NAME="app-service"

echo "🧨 Iniciando destroy da infra ECS"
echo "Região: $AWS_REGION"
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"

# ==============================
# 1. Deletar ECS Service
# ==============================
echo "➡️ Removendo ECS Service..."

aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --desired-count 0 \
  --region $AWS_REGION || true

aws ecs delete-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force \
  --region $AWS_REGION || true

echo "✔ Service removido"

# ==============================
# 2. Aguardar tasks encerrarem
# ==============================
echo "⏳ Aguardando tasks finalizarem..."
sleep 15

# ==============================
# 3. Deletar Cluster
# ==============================
echo "➡️ Deletando cluster ECS..."

aws ecs delete-cluster \
  --cluster $CLUSTER_NAME \
  --region $AWS_REGION || true

echo "✔ Cluster removido"

echo "✅ DESTROY ECS FINALIZADO"
