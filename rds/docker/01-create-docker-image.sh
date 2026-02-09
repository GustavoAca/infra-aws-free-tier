#!/bin/bash
set -e

# =========================================================
# CONFIGURAÇÕES (AJUSTE AQUI)
# =========================================================
AWS_REGION="sa-east-1"
AWS_ACCOUNT_ID="181684851258"

SERVICE_NAME="rds-bootstrap"        # user-service | lista-service | notification-service
IMAGE_TAG="0.0.1"                # ou git hash, ex: $(git rev-parse --short HEAD)

ECR_REPO_NAME="$SERVICE_NAME"
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
IMAGE_URI="$ECR_URI/$ECR_REPO_NAME:$IMAGE_TAG"

# =========================================================
# CHECKS
# =========================================================
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI não encontrado"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker não encontrado"; exit 1; }

echo "▶ Serviço: $SERVICE_NAME"
echo "▶ Imagem:  $IMAGE_URI"

# =========================================================
# LOGIN NO ECR
# =========================================================
echo "🔐 Logando no ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_URI"

# =========================================================
# CRIA REPOSITÓRIO (SE NÃO EXISTIR)
# =========================================================
echo "📦 Verificando repositório ECR..."
aws ecr describe-repositories \
  --repository-names "$ECR_REPO_NAME" \
  --region "$AWS_REGION" >/dev/null 2>&1 || \
aws ecr create-repository \
  --repository-name "$ECR_REPO_NAME" \
  --region "$AWS_REGION" \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability MUTABLE

# =========================================================
# BUILD DA IMAGEM
# =========================================================
echo "🐳 Buildando imagem Docker..."
docker build -t "$SERVICE_NAME:$IMAGE_TAG" .

# =========================================================
# TAG DA IMAGEM
# =========================================================
echo "🏷️  Taggeando imagem..."
docker tag "$SERVICE_NAME:$IMAGE_TAG" "$IMAGE_URI"

# =========================================================
# PUSH PARA O ECR
# =========================================================
echo "🚀 Enviando imagem para o ECR..."
docker push "$IMAGE_URI"

echo "✅ Deploy concluído com sucesso!"
echo "📍 Imagem disponível em:"
echo "   $IMAGE_URI"
