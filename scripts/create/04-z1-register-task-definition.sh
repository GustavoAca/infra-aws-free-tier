#!/bin/bash
set -euo pipefail

AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
TASK_FAMILY="rds-bootstrap"
LAUNCH_TYPE="EC2"
BASE_DIR=$(cd "$(dirname "$0")/../.." && pwd)
TASK_DEF_FILE="$BASE_DIR/ecs/task-definitions/run-task-definition.json"

# --------------------------------------------------
# 1️⃣ Registrar task definition (sempre cria revisão)
# --------------------------------------------------
echo "📦 Registrando task definition rds-bootstrap..."

TASK_DEF_ARN=$(aws ecs register-task-definition \
  --region "$AWS_REGION" \
  --cli-input-json "$(cat "$TASK_DEF_FILE")" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "✅ Task registrada: $TASK_DEF_ARN"

# --------------------------------------------------
# 2️⃣ Descobrir VPC, subnets e SG
# --------------------------------------------------
echo "🔎 Buscando VPC padrão..."
VPC_ID=$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" \
  --output text)

[[ "$VPC_ID" == "None" ]] && echo "❌ VPC padrão não encontrada" && exit 1
echo "✅ VPC: $VPC_ID"

echo "🔎 Buscando subnets..."
SUBNETS=$(aws ec2 describe-subnets \
  --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query "Subnets[].SubnetId" \
  --output text | tr '\t' ',')

echo "✅ Subnets: $SUBNETS"

echo "🔎 Buscando Security Group do ECS..."
SECURITY_GROUP=$(aws ec2 describe-security-groups \
  --region "$AWS_REGION" \
  --filters Name=group-name,Values=ecs-* Name=vpc-id,Values="$VPC_ID" \
  --query "SecurityGroups[0].GroupId" \
  --output text)

echo "✅ Security Group: $SECURITY_GROUP"

# --------------------------------------------------
# 3️⃣ Run-task (one-shot)
# --------------------------------------------------
echo "🚀 Executando bootstrap do RDS..."

aws ecs run-task \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER_NAME" \
  --launch-type "$LAUNCH_TYPE" \
  --task-definition "$TASK_DEF_ARN" \
  --count 1 \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}"

echo "✅ Bootstrap do RDS disparado com sucesso"
