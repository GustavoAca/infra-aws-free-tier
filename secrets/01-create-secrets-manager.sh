#!/bin/bash
set -euo pipefail

# ==============================
# Configurações
# ==============================
AWS_REGION="sa-east-1"
AWS_ACCOUNT_ID="181684851258"
TASK_ROLE_NAME="ecs-task-role-app"
SECRETS_POLICY_NAME="policy-secret-menager"

# ==============================
# Caminho base do script (para localizar arquivos)
# ==============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================
# Secrets definidos (relativos ao script)
# ==============================
declare -A SECRETS=(
  ["lista-service-secrets"]="$SCRIPT_DIR/lista/secrets.json"
  ["users-service-secrets"]="$SCRIPT_DIR/users/secrets.json"
  ["notification-service-secrets"]="$SCRIPT_DIR/notification/secrets.json"
  ["rds-bootstrap-secrets"]="$SCRIPT_DIR/rds-bootstrap/secrets.json"
)

# ==============================
# Helpers
# ==============================
log() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

fail() {
  echo "❌ $*" >&2
  exit 1
}

# ==============================
# Validações iniciais
# ==============================
command -v aws >/dev/null 2>&1 || fail "AWS CLI não encontrado"

CURRENT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
[[ "$CURRENT_ACCOUNT_ID" == "$AWS_ACCOUNT_ID" ]] || \
  fail "Conta AWS incorreta (esperado: $AWS_ACCOUNT_ID | atual: $CURRENT_ACCOUNT_ID)"

log "🔐 Provisionando Secrets Manager (idempotente)"
log "📍 Região: $AWS_REGION"
log "🏦 Account: $AWS_ACCOUNT_ID"
echo

# ==============================
# Funções Secrets Manager
# ==============================
secret_exists() {
  aws secretsmanager describe-secret \
    --secret-id "$1" \
    --region "$AWS_REGION" \
    >/dev/null 2>&1
}

get_secret_value() {
  aws secretsmanager get-secret-value \
    --secret-id "$1" \
    --query SecretString \
    --output text \
    --region "$AWS_REGION" \
    2>/dev/null || echo ""
}

create_or_update_secret() {
  local secret_name=$1
  local secret_file=$2

  [[ -f "$secret_file" ]] || fail "Arquivo não encontrado: $secret_file"
  local secret_content
  secret_content=$(<"$secret_file")

  if secret_exists "$secret_name"; then
    # Comparar valor atual do Secret
    local current_value
    current_value=$(get_secret_value "$secret_name")
    if [[ "$current_value" != "$secret_content" ]]; then
      log "♻️  Atualizando secret: $secret_name"
      aws secretsmanager put-secret-value \
        --secret-id "$secret_name" \
        --secret-string "$secret_content" \
        --region "$AWS_REGION" \
        >/dev/null
      log "✅ Secret atualizado: $secret_name"
    else
      log "⚠️  Secret já está atualizado: $secret_name"
    fi
  else
    log "➕ Criando secret: $secret_name"
    aws secretsmanager create-secret \
      --name "$secret_name" \
      --description "Secrets do ${secret_name}" \
      --secret-string "$secret_content" \
      --region "$AWS_REGION" \
      >/dev/null
    log "✅ Secret criado: $secret_name"
  fi
}

# ==============================
# Provisionamento dos Secrets
# ==============================
for SECRET_NAME in "${!SECRETS[@]}"; do
  log "🔎 Processando secret: $SECRET_NAME"
  create_or_update_secret "$SECRET_NAME" "${SECRETS[$SECRET_NAME]}"
  echo
done

# ==============================
# Criar policy customizada se não existir
# ==============================
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${SECRETS_POLICY_NAME}"

if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  log "⚠️  Policy já existe: $SECRETS_POLICY_NAME"
else
  log "➕ Criando policy customizada: $SECRETS_POLICY_NAME"
  aws iam create-policy \
    --policy-name "$SECRETS_POLICY_NAME" \
    --policy-document '{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "secretsmanager:GetSecretValue",
                  "secretsmanager:DescribeSecret"
              ],
              "Resource": "*"
          }
      ]
    }' >/dev/null
  log "✅ Policy criada: $SECRETS_POLICY_NAME"
fi

# ==============================
# Anexar policy à Task Role (idempotente)
# ==============================
log "🔗 Garantindo policy anexada à role: $TASK_ROLE_NAME"

if aws iam list-attached-role-policies \
      --role-name "$TASK_ROLE_NAME" \
      --output text \
    | awk '{print $2}' \
    | grep -Fxq "$POLICY_ARN"; then
  log "⚠️  Policy já anexada: $SECRETS_POLICY_NAME"
else
  aws iam attach-role-policy \
    --role-name "$TASK_ROLE_NAME" \
    --policy-arn "$POLICY_ARN"
  log "✅ Policy anexada com sucesso"
fi

echo
log "🎯 Provisionamento concluído com sucesso"
