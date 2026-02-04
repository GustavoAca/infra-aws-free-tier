#!/bin/bash
set -euo pipefail

# ============================================================
# Configurações globais
# ============================================================
AWS_REGION="sa-east-1"
export AWS_REGION

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
POLICY_DIR="$BASE_DIR/ecs/policies"

# Roles
INSTANCE_ROLE="ecsInstanceRole"
EXEC_ROLE="ecsTaskExecutionRole"
TASK_ROLE="ecs-task-role-app"

# Policies
APP_POLICY_NAME="ecs-app-secrets-policy"
EXEC_POLICY_NAME="ecs-execution-secrets-policy"

APP_POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$APP_POLICY_NAME"
EXEC_POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$EXEC_POLICY_NAME"

echo "🔐 Provisionando IAM para ECS"
echo "🏦 Account ID : $ACCOUNT_ID"
echo "📂 Policy dir: $POLICY_DIR"
echo

# ============================================================
# Validação obrigatória dos arquivos
# ============================================================
REQUIRED_POLICIES=(
  ecs-instance-trust.json
  ecs-task-trust.json
  ecs-app-secrets-policy.json
  ecs-execution-secrets-policy.json
)

for file in "${REQUIRED_POLICIES[@]}"; do
  if [[ ! -f "$POLICY_DIR/$file" ]]; then
    echo "❌ Arquivo de policy não encontrado: $POLICY_DIR/$file"
    exit 1
  fi
done

echo "✅ Todas as policies encontradas"
echo

# ============================================================
# 1️⃣ Instance Role (EC2 / ECS Agent)
# ============================================================
if aws iam get-role --role-name "$INSTANCE_ROLE" >/dev/null 2>&1; then
  echo "⚡ Instance Role já existe: $INSTANCE_ROLE"
else
  echo "➕ Criando Instance Role: $INSTANCE_ROLE"
  aws iam create-role \
    --role-name "$INSTANCE_ROLE" \
    --assume-role-policy-document "$(cat "$POLICY_DIR/ecs-instance-trust.json")"
fi

aws iam attach-role-policy \
  --role-name "$INSTANCE_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role || true

aws iam attach-role-policy \
  --role-name "$INSTANCE_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore || true

if ! aws iam get-instance-profile --instance-profile-name "$INSTANCE_ROLE" >/dev/null 2>&1; then
  echo "➕ Criando Instance Profile"
  aws iam create-instance-profile \
    --instance-profile-name "$INSTANCE_ROLE"

  aws iam add-role-to-instance-profile \
    --instance-profile-name "$INSTANCE_ROLE" \
    --role-name "$INSTANCE_ROLE"
fi

echo "✅ Instance Role configurada"
echo

# ============================================================
# 2️⃣ Execution Role (ECS + Secrets Manager)
# ============================================================
if aws iam get-role --role-name "$EXEC_ROLE" >/dev/null 2>&1; then
  echo "⚡ Execution Role já existe: $EXEC_ROLE"
else
  echo "➕ Criando Execution Role: $EXEC_ROLE"
  aws iam create-role \
    --role-name "$EXEC_ROLE" \
    --assume-role-policy-document "$(cat "$POLICY_DIR/ecs-task-trust.json")"
fi

aws iam attach-role-policy \
  --role-name "$EXEC_ROLE" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || true

if ! aws iam get-policy --policy-arn "$EXEC_POLICY_ARN" >/dev/null 2>&1; then
  echo "➕ Criando policy Execution (Secrets Manager)"
  aws iam create-policy \
    --policy-name "$EXEC_POLICY_NAME" \
    --policy-document "$(cat "$POLICY_DIR/ecs-execution-secrets-policy.json")"
fi

aws iam attach-role-policy \
  --role-name "$EXEC_ROLE" \
  --policy-arn "$EXEC_POLICY_ARN" || true

echo "✅ Execution Role configurada"
echo

# ============================================================
# 3️⃣ Task Role (Permissões da aplicação)
# ============================================================
if aws iam get-role --role-name "$TASK_ROLE" >/dev/null 2>&1; then
  echo "⚡ Task Role já existe: $TASK_ROLE"
else
  echo "➕ Criando Task Role: $TASK_ROLE"
  aws iam create-role \
    --role-name "$TASK_ROLE" \
    --assume-role-policy-document "$(cat "$POLICY_DIR/ecs-task-trust.json")"
fi

if ! aws iam get-policy --policy-arn "$APP_POLICY_ARN" >/dev/null 2>&1; then
  echo "➕ Criando policy da aplicação"
  aws iam create-policy \
    --policy-name "$APP_POLICY_NAME" \
    --policy-document "$(cat "$POLICY_DIR/ecs-app-secrets-policy.json")"
fi

aws iam attach-role-policy \
  --role-name "$TASK_ROLE" \
  --policy-arn "$APP_POLICY_ARN" || true

echo "✅ Task Role configurada"
echo

# ============================================================
# FINAL
# ============================================================
echo "🎯 IAM ECS provisionado com sucesso"
echo
echo "➡️ Instance Role  : $INSTANCE_ROLE"
echo "➡️ Execution Role : $EXEC_ROLE"
echo "➡️ Task Role      : $TASK_ROLE"
