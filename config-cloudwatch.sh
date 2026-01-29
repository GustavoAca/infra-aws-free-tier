#!/bin/bash
set -e

./cloudwatch/01-cloudwatch-logs-retention.sh

./cloudwatch/alarms/01-alarm-ecs-service-down.sh

./cloudwatch/alarms/02-alarm-ecs-task-stopped.sh

./cloudwatch/alarms/03-alarm-ecs-memory-high.sh