#!/bin/bash
set -e

echo "🚀 Iniciando criação completa da infra AWS Free Tier"

./scripts/create/01-ecr.sh

./scripts/create/02-ecs-cluster.sh

./scripts/create/03-ec2.sh

./scripts/create/04-register-task-definition.sh

./scripts/create/05-ecs-service.sh

echo "✅ Infra criada com sucesso"