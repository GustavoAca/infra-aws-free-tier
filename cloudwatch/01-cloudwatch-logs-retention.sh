#!/usr/bin/env bash
set -euo pipefail

REGION="sa-east-1"
RETENTION_DAYS=7

LOG_GROUPS=(
  "ecs-user-service"
  "ecs-lista-service"
  "ecs-notification-service"
  "ecs-nginx"
)

echo "🔧 Configurando retenção de logs no CloudWatch..."

for LOG_GROUP in "${LOG_GROUPS[@]}"; do
  echo "➡️  Ajustando retenção para $LOG_GROUP"

  aws logs create-log-group \
    --log-group-name "$LOG_GROUP" \
    --region "$REGION" 2>/dev/null || true

  aws logs put-retention-policy \
    --log-group-name "$LOG_GROUP" \
    --retention-in-days "$RETENTION_DAYS" \
    --region "$REGION"

done

echo "✅ Retenção configurada com sucesso"
