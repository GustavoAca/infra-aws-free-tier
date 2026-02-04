#!/usr/bin/env bash
set -e

REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
SERVICE_NAME="app-service"
ALARM_NAME="ecs-${SERVICE_NAME}-down"

aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "$ALARM_NAME" \
  --alarm-description "ECS service sem tasks rodando" \
  --namespace AWS/ECS \
  --metric-name RunningTaskCount \
  --dimensions Name=ClusterName,Value=$CLUSTER_NAME Name=ServiceName,Value=$SERVICE_NAME \
  --statistic Minimum \
  --period 60 \
  --evaluation-periods 3 \
  --threshold 1 \
  --comparison-operator LessThanThreshold \
  --treat-missing-data notBreaching
