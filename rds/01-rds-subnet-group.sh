#!/bin/bash
set -e

AWS_REGION="sa-east-1"
SUBNET_GROUP_NAME="infra-aws-free-tier-subnet-group"
TAG_KEY="Project"
TAG_VALUE="infra-aws-free-tier"

echo "🔎 Verificando DB Subnet Group: $SUBNET_GROUP_NAME"

EXISTS=$(aws rds describe-db-subnet-groups \
  --region $AWS_REGION \
  --db-subnet-group-name $SUBNET_GROUP_NAME \
  --query "DBSubnetGroups[0].DBSubnetGroupName" \
  --output text 2>/dev/null || echo "NONE")

if [[ "$EXISTS" == "NONE" || "$EXISTS" == "None" ]]; then
  echo "➕ Criando DB Subnet Group"

  SUBNET_IDS=$(aws ec2 describe-subnets \
    --region $AWS_REGION \
    --query "Subnets[].SubnetId" \
    --output text)

  aws rds create-db-subnet-group \
    --region $AWS_REGION \
    --db-subnet-group-name $SUBNET_GROUP_NAME \
    --db-subnet-group-description "Subnet group for infra-aws-free-tier" \
    --subnet-ids $SUBNET_IDS \
    --tags Key=$TAG_KEY,Value=$TAG_VALUE

  echo "✅ DB Subnet Group criado"
else
  echo "✔ DB Subnet Group já existe — pulando criação"
fi
