#!/usr/bin/env bash
set -e

REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
SERVICE_NAME="app-service"
ALARM_NAME="ecs-${SERVICE_NAME}-memory-high"

aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "$ALARM_NAME" \
  --alarm-description "Uso de memória alto no ECS Service" \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ClusterName,Value=$CLUSTER_NAME Name=ServiceName,Value=$SERVICE_NAME \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching
