#!/bin/bash
set -e

# ==============================
# Diretórios
# ==============================
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)

TASK_FILE="$ROOT_DIR/ecs/task-definitions/app-task-definition.json"
GEN_TASK_FILE="$ROOT_DIR/ecs/task-definitions/app-task-definition.gen.json"

REGION="sa-east-1"

# ==============================
# AWS Account
# ==============================
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "📄 Task file origem: $TASK_FILE"
echo "🛠️ Task file gerado: $GEN_TASK_FILE"
echo "🧾 Account ID: $ACCOUNT_ID"

# ==============================
# 1️⃣ Valida existência
# ==============================
if [[ ! -f "$TASK_FILE" ]]; then
  echo "❌ ERRO: Task definition não encontrada"
  exit 1
fi

# ==============================
# 2️⃣ Gera o JSON final
# ==============================
sed "s/ACCOUNT_ID/$ACCOUNT_ID/g" "$TASK_FILE" > "$GEN_TASK_FILE"

# ==============================
# 3️⃣ Valida geração
# ==============================
if [[ ! -f "$GEN_TASK_FILE" ]]; then
  echo "❌ ERRO: Falha ao gerar task definition final"
  exit 1
fi

echo "✅ Task definition gerada com sucesso"

# ==============================
# 4️⃣ Converte path para Windows (CRÍTICO)
# ==============================
GEN_TASK_FILE_WIN=$(cygpath -w "$GEN_TASK_FILE")

echo "🪟 Path Windows: $GEN_TASK_FILE_WIN"

# ==============================
# 5️⃣ Registra no ECS
# ==============================
aws ecs register-task-definition \
  --region "$REGION" \
  --cli-input-json "file://$GEN_TASK_FILE_WIN"

echo "🚀 Task definition registrada no ECS com sucesso"
