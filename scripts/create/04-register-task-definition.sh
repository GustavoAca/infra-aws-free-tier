#!/bin/bash
set -e

AWS_REGION="sa-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TASK_FILE="ecs/task-definitions/app-task-definition.json"

echo "Registrando Task Definition..."
echo "Conta: $ACCOUNT_ID"
echo "Região: $AWS_REGION"

sed "s/ACCOUNT_ID/$ACCOUNT_ID/g" $TASK_FILE > /tmp/task-def.json

aws ecs register-task-definition \
  --cli-input-json file:///tmp/task-def.json \
  --region $AWS_REGION

echo "✅ Task Definition registrada com sucesso"
