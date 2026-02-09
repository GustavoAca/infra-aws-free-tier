#!/bin/bash
set -e

AWS_REGION="sa-east-1"

echo "🔥 INICIANDO LIMPEZA COMPLETA AWS"
echo "Região: $AWS_REGION"
echo ""

############################################
# ECR - Delete repositories
############################################
echo "➡️ Limpando ECR repositories..."

REPOS=$(aws ecr describe-repositories \
  --region $AWS_REGION \
  --query "repositories[].repositoryName" \
  --output text || true)

for repo in $REPOS; do
  echo "🗑 Deletando ECR repo: $repo"
  aws ecr delete-repository \
    --repository-name "$repo" \
    --force \
    --region $AWS_REGION || true
done

echo "✔ ECR limpo"
echo ""

############################################
# EBS - Delete available volumes
############################################
echo "➡️ Limpando volumes EBS órfãos..."

VOLUMES=$(aws ec2 describe-volumes \
  --region $AWS_REGION \
  --filters Name=status,Values=available \
  --query "Volumes[].VolumeId" \
  --output text || true)

for vol in $VOLUMES; do
  echo "🗑 Deletando volume: $vol"
  aws ec2 delete-volume \
    --volume-id "$vol" \
    --region $AWS_REGION || true
done

echo "✔ Volumes EBS limpos"
echo ""

############################################
# EBS Snapshots
############################################
echo "➡️ Limpando snapshots EBS..."

SNAPS=$(aws ec2 describe-snapshots \
  --owner-ids self \
  --region $AWS_REGION \
  --query "Snapshots[].SnapshotId" \
  --output text || true)

for snap in $SNAPS; do
  echo "🗑 Deletando snapshot: $snap"
  aws ec2 delete-snapshot \
    --snapshot-id "$snap" \
    --region $AWS_REGION || true
done

echo "✔ Snapshots EBS limpos"
echo ""

############################################
# Elastic IP
############################################
echo "➡️ Limpando Elastic IP..."

EIPS=$(aws ec2 describe-addresses \
  --region $AWS_REGION \
  --query "Addresses[].AllocationId" \
  --output text || true)

for eip in $EIPS; do
  echo "🗑 Liberando Elastic IP: $eip"
  aws ec2 release-address \
    --allocation-id "$eip" \
    --region $AWS_REGION || true
done

echo "✔ Elastic IP limpos"
echo ""

############################################
# Secrets Manager
############################################
echo "➡️ Limpando Secrets Manager..."

SECRETS=$(aws secretsmanager list-secrets \
  --region $AWS_REGION \
  --query "SecretList[].Name" \
  --output text || true)

for secret in $SECRETS; do
  echo "🗑 Deletando secret: $secret"
  aws secretsmanager delete-secret \
    --secret-id "$secret" \
    --force-delete-without-recovery \
    --region $AWS_REGION || true
done

echo "✔ Secrets removidos"
echo ""

############################################
# RDS Snapshots
############################################
echo "➡️ Limpando snapshots RDS..."

RDS_SNAPS=$(aws rds describe-db-snapshots \
  --region $AWS_REGION \
  --query "DBSnapshots[].DBSnapshotIdentifier" \
  --output text || true)

for snap in $RDS_SNAPS; do
  echo "🗑 Deletando snapshot RDS: $snap"
  aws rds delete-db-snapshot \
    --db-snapshot-identifier "$snap" \
    --region $AWS_REGION || true
done

echo "✔ Snapshots RDS removidos"
echo ""

############################################
# CloudWatch Logs
############################################
echo "➡️ Limpando CloudWatch Log Groups..."

LOGS=$(aws logs describe-log-groups \
  --region $AWS_REGION \
  --query "logGroups[].logGroupName" \
  --output text || true)

for log in $LOGS; do
  echo "🗑 Deletando log group: $log"
  aws logs delete-log-group \
    --log-group-name "$log" \
    --region $AWS_REGION || true
done

echo "✔ CloudWatch limpo"
echo ""

echo "✅ LIMPEZA COMPLETA FINALIZADA"
