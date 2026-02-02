#!/bin/bash
set -e

# ==============================
# Diretórios
# ==============================
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
POLICY_FILE="$SCRIPT_DIR/ecs-trust-policy.json"
GEN_POLICY_FILE="$SCRIPT_DIR/ecs-trust-policy-gen.json"

# ==============================
# 0️⃣ Pega Account ID
# ==============================
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# ==============================
# 1️⃣ Valida existência do JSON original
# ==============================
if [[ ! -f "$POLICY_FILE" ]]; then
  echo "❌ ERRO: Policy não encontrada em $POLICY_FILE"
  exit 1
fi

# ==============================
# 2️⃣ Gera o JSON final
# ==============================
sed "s/ACCOUNT_ID/$ACCOUNT_ID/g" "$POLICY_FILE" > "$GEN_POLICY_FILE"

# ==============================
# 3️⃣ Valida geração
# ==============================
if [[ ! -f "$GEN_POLICY_FILE" ]]; then
  echo "❌ ERRO: Falha ao gerar policy final"
  exit 1
fi

# ==============================
# 4️⃣ Converte path para Windows (opcional)
# ==============================
if command -v cygpath &> /dev/null; then
  GEN_POLICY_FILE_WIN=$(cygpath -w "$GEN_POLICY_FILE")
else
  GEN_POLICY_FILE_WIN="$GEN_POLICY_FILE"
fi

# ==============================
# 5️⃣ Verifica/Cria a Role
# ==============================
ROLE_NAME="ecsInstanceRole"
ROLE_EXISTS=$(aws iam get-role --role-name $ROLE_NAME --query "Role.RoleName" --output text 2>/dev/null || echo "NONE")

if [[ "$ROLE_EXISTS" == "$ROLE_NAME" ]]; then
  echo "⚡ IAM Role $ROLE_NAME já existe"
else
  echo "➕ Criando IAM Role $ROLE_NAME..."
  aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document "file://$GEN_POLICY_FILE_WIN"
fi

# ==============================
# 6️⃣ Anexa Policies (ECS e SSM)
# ==============================
echo "🔗 Anexando policies..."

# Permissão para o ECS Agent funcionar
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role

# Permissão para o Session Manager (SSM) funcionar
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

echo "✅ IAM Role configurada com sucesso"

# ==============================
# 7️⃣ Verifica/Cria Instance Profile
# ==============================
PROFILE_EXISTS=$(aws iam get-instance-profile --instance-profile-name $ROLE_NAME --query "InstanceProfile.InstanceProfileName" --output text 2>/dev/null || echo "NONE")

if [[ "$PROFILE_EXISTS" == "$ROLE_NAME" ]]; then
  echo "⚡ Instance Profile $ROLE_NAME já existe"
else
  echo "➕ Criando Instance Profile..."
  aws iam create-instance-profile --instance-profile-name $ROLE_NAME
  aws iam add-role-to-instance-profile --instance-profile-name $ROLE_NAME --role-name $ROLE_NAME
  echo "✅ Instance Profile criado"
fi
