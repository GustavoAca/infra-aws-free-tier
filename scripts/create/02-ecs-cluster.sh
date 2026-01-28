#!/bin/bash
set -e

# ==============================
# Configurações
# ==============================
AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"

echo "Região: $AWS_REGION"
echo "Cluster ECS: $CLUSTER_NAME"

# ==============================
# Verificar se o cluster já existe
# ==============================
EXISTING_CLUSTER=$(aws ecs describe-clusters \
  --clusters "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query "clusters[0].status" \
  --output text 2>/dev/null || echo "NONE")

if [[ "$EXISTING_CLUSTER" == "ACTIVE" ]]; then
  echo "✔ Cluster '$CLUSTER_NAME' já existe e está ativo"
else
  echo "➕ Criando cluster ECS '$CLUSTER_NAME'"
  aws ecs create-cluster \
    --cluster-name "$CLUSTER_NAME" \
    --region "$AWS_REGION"
  echo "✅ Cluster criado com sucesso"
fi