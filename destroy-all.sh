#!/bin/bash
set -e

echo "🚀 Iniciando criação completa da infra AWS Free Tier RDS"

./scripts/destroy/01-destroy-ecs.sh

./scripts/destroy/02-destroy-ec2.sh

./scripts/destroy/03-destroy-rds.sh