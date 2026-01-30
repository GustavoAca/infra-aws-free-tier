#!/bin/bash
set -e

# ==============================
# Configurações
# ==============================
AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
INSTANCE_TYPE="t3.small" # ATENÇÃO: t3.small NÃO É FREE TIER.
KEY_NAME="ecs-key"
SECURITY_GROUP_NAME="ecs-sg"
IAM_ROLE_NAME="ecsInstanceRole"
TAG_PROJECT="infra-aws-free-tier"

echo "Região: $AWS_REGION"
echo "Cluster ECS: $CLUSTER_NAME"

# ==============================
# 0️⃣ Garantir que a key pair existe
# ==============================
CLUSTER_STATUS=$(aws ecs describe-clusters \
  --clusters "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query "clusters[0].status" \
  --output text 2>/dev/null || echo "NONE")

if [[ "$CLUSTER_STATUS" != "ACTIVE" ]]; then
  echo "➕ Criando cluster ECS"
  aws ecs create-cluster \
    --cluster-name "$CLUSTER_NAME" \
    --region "$AWS_REGION" >/dev/null
else
  echo "⚡ Cluster ECS já existe"
fi

# ==============================
# 2️⃣ IAM Instance Profile
# ==============================
aws iam get-instance-profile \
  --instance-profile-name "$IAM_ROLE_NAME" >/dev/null 2>&1 || {
    echo "➕ Criando Instance Profile"
    aws iam create-instance-profile \
      --instance-profile-name "$IAM_ROLE_NAME"

    aws iam add-role-to-instance-profile \
      --instance-profile-name "$IAM_ROLE_NAME" \
      --role-name "$IAM_ROLE_NAME"
}

aws iam attach-role-policy \
  --role-name "$IAM_ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role \
  >/dev/null 2>&1 || true

aws iam attach-role-policy \
  --role-name "$IAM_ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore \
  >/dev/null 2>&1 || true

# ==============================
# 3️⃣ VPC / Subnet Default
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
# 4️⃣ Security Group
# ==============================
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values="$SECURITY_GROUP_NAME" Name=vpc-id,Values="$VPC_ID" \
  --region "$AWS_REGION" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || true)

if [[ -z "$SG_ID" || "$SG_ID" == "None" ]]; then
  echo "➕ Criando Security Group"
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
    --port 8080-8090 \
    --cidr 0.0.0.0/0 \
    --region "$AWS_REGION"
fi

# ==============================
# 5️⃣ AMI ECS Optimized (OFICIAL)
# ==============================
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters \
    "Name=name,Values=amzn2-ami-ecs-hvm-*-x86_64-ebs" \
    "Name=state,Values=available" \
  --region "$AWS_REGION" \
  --query "Images | sort_by(@, &CreationDate)[-1].ImageId" \
  --output text)

if [[ -z "$AMI_ID" || "$AMI_ID" == "None" ]]; then
  echo "❌ ERRO: AMI ECS Optimized não encontrada em $AWS_REGION"
  exit 1
fi

echo "✅ AMI ECS Optimized: $AMI_ID"


echo "AMI ECS Optimized: $AMI_ID"

# ==============================
# 6️⃣ USER DATA (ECS AGENT) — CORRETO
# ==============================
USER_DATA=$(cat <<EOF
#!/bin/bash
set -eux

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "🧹 Reset ECS"
systemctl stop ecs || true
rm -rf /var/lib/ecs/*
rm -f /etc/ecs/ecs.config

mkdir -p /etc/ecs

cat <<ECSCONF > /etc/ecs/ecs.config
ECS_CLUSTER=$CLUSTER_NAME
ECS_LOGLEVEL=info
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECSCONF

echo "📄 ecs.config:"
cat /etc/ecs/ecs.config

systemctl daemon-reexec
systemctl restart docker
systemctl enable ecs
systemctl restart ecs

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

echo "✅ User Data finalizado"
EOF
)

# ==============================
# 7️⃣ Criar EC2
# ==============================
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
  --tag-specifications \
    "ResourceType=instance,Tags=[{Key=Project,Value=$TAG_PROJECT},{Key=Name,Value=ecs-app-instance}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "🚀 EC2 criada: $INSTANCE_ID"

# ==============================
# 8️⃣ Aguardar registro no ECS
# ==============================
echo "⏳ Aguardando EC2 registrar no ECS..."

for i in {1..30}; do
  COUNT=$(aws ecs describe-clusters \
    --clusters "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query "clusters[0].registeredContainerInstancesCount" \
    --output text)

  [[ "$COUNT" -ge 1 ]] && break
  sleep 10
done

echo "✅ EC2 registrada no ECS"

# ==============================
# 9️⃣ Acesso SSM
# ==============================
echo "SSM:"
echo "aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION"
