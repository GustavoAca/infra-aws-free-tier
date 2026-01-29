#!/bin/bash
set -e

AWS_REGION="sa-east-1"
TAG_KEY="Project"
TAG_VALUE="infra-aws-free-tier"

echo "🧨 Procurando EC2 com tag:"
echo "  $TAG_KEY=$TAG_VALUE"
echo "Região: $AWS_REGION"

INSTANCE_IDS=$(aws ec2 describe-instances \
  --region $AWS_REGION \
  --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [[ -z "$INSTANCE_IDS" ]]; then
  echo "✔ Nenhuma EC2 encontrada para destruir"
  exit 0
fi

echo "⚠️ As seguintes EC2 serão TERMINADAS:"
echo "$INSTANCE_IDS"
echo ""

aws ec2 terminate-instances \
  --instance-ids $INSTANCE_IDS \
  --region $AWS_REGION

echo "⏳ Aguardando término das instâncias..."

aws ec2 wait instance-terminated \
  --instance-ids $INSTANCE_IDS \
  --region $AWS_REGION

echo "✅ EC2 destruídas com sucesso"
