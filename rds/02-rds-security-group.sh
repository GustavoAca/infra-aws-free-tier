#!/bin/bash
set -e

AWS_REGION="sa-east-1"
SG_NAME="rds-sg-infra-aws-free-tier"
TAG_KEY="Project"
TAG_VALUE="infra-aws-free-tier"

echo "🔎 Buscando VPC default..."
VPC_ID=$(aws ec2 describe-vpcs \
  --region $AWS_REGION \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" \
  --output text)

echo "✔ VPC: $VPC_ID"

# ==============================
# Buscar ou criar Security Group do RDS
# ==============================
echo "🔎 Verificando Security Group do RDS..."

RDS_SG_ID=$(aws ec2 describe-security-groups \
  --region $AWS_REGION \
  --filters Name=group-name,Values=$SG_NAME Name=vpc-id,Values=$VPC_ID \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "NONE")

if [[ "$RDS_SG_ID" == "NONE" || "$RDS_SG_ID" == "None" ]]; then
  echo "➕ Criando Security Group do RDS..."

  RDS_SG_ID=$(aws ec2 create-security-group \
    --group-name $SG_NAME \
    --description "RDS access for infra-aws-free-tier" \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --query GroupId \
    --output text)

  aws ec2 create-tags \
    --resources $RDS_SG_ID \
    --tags Key=$TAG_KEY,Value=$TAG_VALUE \
    --region $AWS_REGION

  echo "✅ Security Group do RDS criado: $RDS_SG_ID"
else
  echo "✔ Security Group do RDS já existe: $RDS_SG_ID"
fi

# ==============================
# Obter Security Group da EC2 (ECS)
# ==============================
echo "🔎 Buscando Security Group da EC2 (ECS)..."

ECS_SG_ID=$(aws ec2 describe-instances \
  --region $AWS_REGION \
  --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
            "Name=instance-state-name,Values=running,stopped,pending" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
  --output text)

if [[ -z "$ECS_SG_ID" || "$ECS_SG_ID" == "None" ]]; then
  echo "❌ ERRO: Security Group da EC2 (ECS) não encontrado"
  exit 1
fi

echo "✔ ECS Security Group: $ECS_SG_ID"

# ==============================
# Autorizar acesso do ECS ao RDS
# ==============================
echo "🔐 Liberando acesso ECS → RDS (5432)..."

aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_SG_ID \
  --region $AWS_REGION 2>/dev/null || echo "✔ Regra já existe"

echo "✅ Security Group do RDS pronto para uso"
