#!/bin/bash
set -e

# ==============================
# Configurações
# ==============================
AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
INSTANCE_TYPE="t3.small" # FREE TIER
SECURITY_GROUP_NAME="ecs-sg"
IAM_ROLE_NAME="ecsInstanceRole"
TAG_PROJECT="infra-aws-free-tier"

echo "Região: $AWS_REGION"
echo "Cluster ECS: $CLUSTER_NAME"

# ==============================
# 1️⃣ Garantir que o Cluster ECS existe
# ==============================
CLUSTER_DESC=$(aws ecs describe-clusters \
  --clusters "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --output json 2>/dev/null || echo "{}")

CLUSTER_STATUS=$(aws ecs describe-clusters \
  --clusters "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query "clusters[0].status" \
  --output text 2>/dev/null || echo "NONE")


if [[ "$CLUSTER_STATUS" == "ACTIVE" ]]; then
  echo "✅ Cluster ECS ativo"
elif [[ "$CLUSTER_STATUS" == "INACTIVE" ]]; then
  echo "♻️ Cluster ECS inativo encontrado, recriando..."
  aws ecs delete-cluster \
    --cluster "$CLUSTER_NAME" \
    --region "$AWS_REGION" || true

  aws ecs create-cluster \
    --cluster-name "$CLUSTER_NAME" \
    --region "$AWS_REGION" >/dev/null
else
  echo "➕ Criando cluster ECS..."
  aws ecs create-cluster \
    --cluster-name "$CLUSTER_NAME" \
    --region "$AWS_REGION" >/dev/null
fi

# ==============================
# 2️⃣ VPC / Subnet Default
# ==============================
VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --region "$AWS_REGION" \
  --query "Vpcs[0].VpcId" \
  --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --region "$AWS_REGION" \
  --query "Subnets[0].SubnetId" \
  --output text)

# ==============================
# 3️⃣ Security Group
# ==============================
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values="$SECURITY_GROUP_NAME" Name=vpc-id,Values="$VPC_ID" \
  --region "$AWS_REGION" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || true)

if [[ -z "$SG_ID" || "$SG_ID" == "None" ]]; then
  echo "➕ Criando Security Group..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name "$SECURITY_GROUP_NAME" \
    --description "ECS SG" \
    --vpc-id "$VPC_ID" \
    --region "$AWS_REGION" \
    --query "GroupId" \
    --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region "$AWS_REGION"

  aws ec2 authorize-security-group-egress \
    --group-id "$SG_ID" \
    --protocol -1 \
    --cidr 0.0.0.0/0 \
    --region "$AWS_REGION" || true
fi

# ==============================
# 4️⃣ AMI ECS Optimized (AL2023)
# ==============================
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-ecs-hvm-*-x86_64" "Name=state,Values=available" \
  --region "$AWS_REGION" \
  --query "Images | sort_by(@, &CreationDate)[-1].ImageId" \
  --output text)

echo "✅ AMI ECS Optimized: $AMI_ID"

# ==============================
# 5️⃣ USER DATA (ROBUSTO)
# ==============================
USER_DATA=$(cat <<EOF
#!/bin/bash
set -eux

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "🛠 Bootstrap ECS (AL2023)"

# Garantir diretório
mkdir -p /etc/ecs

# Config ECS
cat <<ECSCONF > /etc/ecs/ecs.config
ECS_CLUSTER=${CLUSTER_NAME}
ECS_LOGLEVEL=info
ECSCONF

echo "✅ ecs.config criado"

# Reiniciar ECS Agent (ESSENCIAL)
systemctl daemon-reload
systemctl enable ecs
systemctl restart ecs

echo "🚀 ECS Agent iniciado"
systemctl status ecs --no-pager
reboot
EOF
)

# ==============================
# 6️⃣ Criar EC2
# ==============================
EXISTING_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=$TAG_PROJECT" "Name=instance-state-name,Values=running,pending" \
  --region "$AWS_REGION" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

if [[ "$EXISTING_INSTANCE" != "None" && -n "$EXISTING_INSTANCE" ]]; then
  echo "⚡ EC2 já existe: $EXISTING_INSTANCE"
  INSTANCE_ID=$EXISTING_INSTANCE
else
  echo "🚀 Criando nova EC2..."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --iam-instance-profile Name="$IAM_ROLE_NAME" \
    --associate-public-ip-address \
    --user-data "$USER_DATA" \
    --region "$AWS_REGION" \
    --count 1 \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Project,Value=$TAG_PROJECT},{Key=Name,Value=ecs-app-instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)
fi

echo "🚀 EC2 ID: $INSTANCE_ID"

# ==============================
# 7️⃣ Aguardar registro no ECS
# ==============================
aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION"

echo "⏳ Aguardando registro no ECS..."

for i in {1..40}; do
  COUNT=$(aws ecs describe-clusters \
    --clusters "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query "clusters[0].registeredContainerInstancesCount" \
    --output text)

  if [[ "$COUNT" -ge 1 ]]; then
    echo "✅ ECS registrado com sucesso!"
    exit 0
  fi

  echo "[$i/40] aguardando..."
  sleep 10
done

echo "❌ Timeout aguardando ECS"
exit 1