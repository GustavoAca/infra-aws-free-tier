#!/bin/bash
set -e

echo "🚀 Iniciando criação completa da infra AWS Free Tier"

# 1. Infraestrutura Base (IAM, ECR, Cluster, EC2)
echo "--- 1. Configurando Computação (ECS/EC2) ---"
./ecs/01-create-iam-role-ecs-to-ecs.sh
./secrets/01-create-secrets-manager.sh
./scripts/create/01-ecr.sh
./scripts/create/02-ecs-cluster.sh
./scripts/create/03-ec2.sh
./scripts/create/04-register-task-definition.sh

# 2. Infraestrutura de Dados (RDS)
echo "--- 2. Configurando Banco de Dados (RDS) ---"
./create-rds.sh

# 3. Aplicação (Service)
# Só roda depois que o banco e a EC2 estiverem prontos
echo "--- 3. Subindo Aplicação (ECS Service) ---"
./scripts/create/04-z1-register-task-definition.sh
./scripts/create/05-ecs-service.sh

echo "✅ Infra completa criada com sucesso!"
