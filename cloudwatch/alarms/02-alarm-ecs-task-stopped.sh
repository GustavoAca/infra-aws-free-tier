#!/usr/bin/env bash
set -e

REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
ALARM_NAME="ecs-task-stopped"

aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "$ALARM_NAME" \
  --alarm-description "Tasks ECS parando inesperadamente" \
  --namespace AWS/ECS \
  --metric-name TaskStoppedCount \
  --dimensions Name=ClusterName,Value=$CLUSTER_NAME \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching
