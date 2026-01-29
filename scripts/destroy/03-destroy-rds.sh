#!/bin/bash
set -e

AWS_REGION="sa-east-1"

aws rds delete-db-instance \
  --region $AWS_REGION \
  --db-instance-identifier infra-aws-free-tier-db \
  --skip-final-snapshot \
  --delete-automated-backups

aws rds wait db-instance-deleted \
  --region $AWS_REGION \
  --db-instance-identifier infra-aws-free-tier-db

echo "✅ RDS destruído com sucesso"
