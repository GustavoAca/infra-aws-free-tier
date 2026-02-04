#!/bin/bash
set -e

# ==============================
# Configurações
# ==============================
AWS_REGION="sa-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

REPOSITORIES=(
  "user-service"
  "lista-service"
  "notification-service"
  "nginx"
  "rds-bootstrap"
)

echo "Conta AWS: $ACCOUNT_ID"
echo "Região: $AWS_REGION"
echo "Criando repositórios ECR..."

# ==============================
# Criação dos repositórios
# ==============================
for REPO in "${REPOSITORIES[@]}"; do
  if aws ecr describe-repositories \
      --repository-names "$REPO" \
      --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "✔ Repositório '$REPO' já existe"
  else
    echo "➕ Criando repositório '$REPO'"
    aws ecr create-repository \
      --repository-name "$REPO" \
      --region "$AWS_REGION" \
      --image-scanning-configuration scanOnPush=false \
      --encryption-configuration encryptionType=AES256
  fi
done

echo "✅ ECR configurado com sucesso"
