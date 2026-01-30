#!/bin/bash
set -e

echo "🚀 Iniciando criação da infraestrutura de Banco de Dados (RDS)"

./rds/00-parameter-group.sh

./rds/01-rds-subnet-group.sh

./rds/02-rds-security-group.sh

./rds/03-rds-instance.sh

echo "✅ Infra de Banco de Dados criada com sucesso"