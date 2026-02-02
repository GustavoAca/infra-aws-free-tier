#!/bin/bash
set -e

AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
SERVICE_NAME="app-service"
TASK_FAMILY="app-task"

echo "Criando ECS Service..."
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"

VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --region $AWS_REGION \
  --query "Vpcs[0].VpcId" \
  --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=$VPC_ID \
  --region $AWS_REGION \
  --query "Subnets[0].SubnetId" \
  --output text)

SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=ecs-sg Name=vpc-id,Values=$VPC_ID \
  --region $AWS_REGION \
  --query "SecurityGroups[0].GroupId" \
  --output text)

if [[ -z "$SUBNET_ID" || -z "$SG_ID" ]]; then
  echo "❌ Subnet ou Security Group não encontrados"
  exit 1
fi

# Verifica se o service já existe
EXISTING_SERVICE=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $AWS_REGION \
  --query "services[0].status" \
  --output text 2>/dev/null || echo "NONE")

if [[ "$EXISTING_SERVICE" == "ACTIVE" ]]; then
  echo "⚡ Service '$SERVICE_NAME' já existe, atualizando para a última task definition..."
  aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID]}" \
    --region $AWS_REGION

  echo "✅ ECS Service atualizado"
  exit 0
fi

# Cria o service
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name $SERVICE_NAME \
  --task-definition $TASK_FAMILY \
  --desired-count 1 \
  --launch-type EC2 \
  --deployment-configuration maximumPercent=200,minimumHealthyPercent=0 \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID]}" \
  --region $AWS_REGION

echo "✅ ECS Service criado com sucesso"
