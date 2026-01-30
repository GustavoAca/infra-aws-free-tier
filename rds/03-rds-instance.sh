#!/bin/bash
set -e

AWS_REGION="sa-east-1"
DB_IDENTIFIER="infra-aws-free-tier-db"
DB_CLASS="db.t4g.micro"
DB_ENGINE="postgres"
DB_NAME="appdb"
DB_USER="glaiss"
DB_PASSWORD="SenhaForte123!"
SUBNET_GROUP="infra-aws-free-tier-subnet-group"
TAG_KEY="Project"
TAG_VALUE="infra-aws-free-tier"

echo "🔎 Verificando se o RDS já existe..."

DB_EXISTS=$(aws rds describe-db-instances \
  --region $AWS_REGION \
  --db-instance-identifier $DB_IDENTIFIER \
  --query "DBInstances[0].DBInstanceIdentifier" \
  --output text 2>/dev/null || echo "NONE")

if [[ "$DB_EXISTS" != "NONE" && "$DB_EXISTS" != "None" ]]; then
  echo "✔ RDS já existe: $DB_IDENTIFIER"
else
  echo "➕ Criando RDS PostgreSQL (Free Tier)..."

  # ==============================
  # Buscar Security Group do RDS
  # ==============================
  RDS_SG_ID=$(aws ec2 describe-security-groups \
    --region $AWS_REGION \
    --filters Name=group-name,Values=rds-sg-infra-aws-free-tier \
    --query "SecurityGroups[0].GroupId" \
    --output text)

  if [[ -z "$RDS_SG_ID" || "$RDS_SG_ID" == "None" ]]; then
    echo "❌ ERRO: Security Group do RDS não encontrado"
    exit 1
  fi

  echo "✔ RDS Security Group: $RDS_SG_ID"

  # ==============================
  # Criar DB Instance
  # ==============================
  aws rds create-db-instance \
    --region "$AWS_REGION" \
    --db-instance-identifier "$DB_IDENTIFIER" \
    --db-instance-class "$DB_CLASS" \
    --engine "$DB_ENGINE" \
    --allocated-storage 20 \
    --master-username "$DB_USER" \
    --master-user-password "$DB_PASSWORD" \
    --db-name "$DB_NAME" \
    --vpc-security-group-ids "$RDS_SG_ID" \
    --db-subnet-group-name "$SUBNET_GROUP" \
    --backup-retention-period 0 \
    --no-publicly-accessible \
    --tags Key="$TAG_KEY",Value="$TAG_VALUE"

  echo "⏳ RDS em criação..."
fi

# ==============================
# Aguardar RDS ficar Available
# ==============================
echo "⏳ Aguardando banco de dados ficar disponível (status: available)..."
echo "Isso pode levar alguns minutos."

aws rds wait db-instance-available \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $AWS_REGION

# Obter Endpoint
ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $AWS_REGION \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)

echo "✅ RDS pronto para uso!"
echo "Endpoint: $ENDPOINT"
