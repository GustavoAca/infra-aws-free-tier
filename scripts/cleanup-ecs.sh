#!/bin/bash
set -e

AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"

echo "🧹 Iniciando limpeza do ECS..."

# 1. Parar todas as tasks no cluster app-cluster
echo "🛑 Parando tasks no cluster '$CLUSTER_NAME'..."
TASKS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --region $AWS_REGION --query "taskArns" --output text)
if [[ -n "$TASKS" && "$TASKS" != "None" ]]; then
  for task in $TASKS; do
    aws ecs stop-task --cluster $CLUSTER_NAME --task $task --region $AWS_REGION
    echo "   Task parada: $task"
  done
else
  echo "   Nenhuma task rodando."
fi

# 2. Remover serviços no cluster app-cluster
echo "🗑️ Removendo serviços no cluster '$CLUSTER_NAME'..."
SERVICES=$(aws ecs list-services --cluster $CLUSTER_NAME --region $AWS_REGION --query "serviceArns" --output text)
if [[ -n "$SERVICES" && "$SERVICES" != "None" ]]; then
  for service in $SERVICES; do
    aws ecs update-service --cluster $CLUSTER_NAME --service $service --desired-count 0 --region $AWS_REGION
    aws ecs delete-service --cluster $CLUSTER_NAME --service $service --region $AWS_REGION --force
    echo "   Serviço removido: $service"
  done
else
  echo "   Nenhum serviço encontrado."
fi

# 3. Limpar cluster 'default' (se existir)
echo "🧹 Verificando cluster 'default'..."
DEFAULT_EXISTS=$(aws ecs describe-clusters --clusters default --region $AWS_REGION --query "clusters[0].status" --output text 2>/dev/null || echo "NONE")

if [[ "$DEFAULT_EXISTS" == "ACTIVE" ]]; then
  echo "   Cluster 'default' encontrado. Tentando limpar..."
  
  # Parar tasks no default
  DEF_TASKS=$(aws ecs list-tasks --cluster default --region $AWS_REGION --query "taskArns" --output text)
  if [[ -n "$DEF_TASKS" && "$DEF_TASKS" != "None" ]]; then
    for task in $DEF_TASKS; do
      aws ecs stop-task --cluster default --task $task --region $AWS_REGION
    done
  fi
  
  # Remover serviços no default
  DEF_SVCS=$(aws ecs list-services --cluster default --region $AWS_REGION --query "serviceArns" --output text)
  if [[ -n "$DEF_SVCS" && "$DEF_SVCS" != "None" ]]; then
    for service in $DEF_SVCS; do
      aws ecs update-service --cluster default --service $service --desired-count 0 --region $AWS_REGION
      aws ecs delete-service --cluster default --service $service --region $AWS_REGION --force
    done
  fi
  
  # Tentar deletar o cluster default (só funciona se não tiver instâncias registradas nele)
  aws ecs delete-cluster --cluster default --region $AWS_REGION || echo "⚠️ Não foi possível deletar o cluster 'default' (pode ter instâncias conectadas)."
else
  echo "   Cluster 'default' não existe ou já está inativo."
fi

echo "✅ Limpeza concluída. Agora você pode rodar o ./create-all.sh novamente."
