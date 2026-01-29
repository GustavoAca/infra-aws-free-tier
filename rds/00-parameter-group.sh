#!/bin/bash
set -e

AWS_REGION="sa-east-1"
PG_NAME="infra-aws-free-tier-pg"
PG_FAMILY="postgres15"

if aws rds describe-db-parameter-groups \
  --db-parameter-group-name $PG_NAME \
  --region $AWS_REGION >/dev/null 2>&1; then
  echo "✔ Parameter Group já existe"
  exit 0
fi

aws rds create-db-parameter-group \
  --db-parameter-group-name $PG_NAME \
  --db-parameter-group-family $PG_FAMILY \
  --description "Postgres tuning Free Tier" \
  --region $AWS_REGION

aws rds modify-db-parameter-group \
  --db-parameter-group-name $PG_NAME \
  --parameters \
  "ParameterName=timezone,ParameterValue=America/Sao_Paulo,ApplyMethod=immediate" \
  "ParameterName=max_connections,ParameterValue=100,ApplyMethod=immediate" \
  "ParameterName=work_mem,ParameterValue=16384,ApplyMethod=immediate" \
  "ParameterName=maintenance_work_mem,ParameterValue=65536,ApplyMethod=immediate"

echo "✅ Parameter Group configurado"
