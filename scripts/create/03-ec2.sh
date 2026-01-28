#!/bin/bash
set -e

# ==============================
# Configurações
# ==============================
AWS_REGION="sa-east-1"
CLUSTER_NAME="app-cluster"
INSTANCE_TYPE="t3.micro"
KEY_NAME="ecs-key"
SECURITY_GROUP_NAME="ecs-sg"

echo "Região: $AWS_REGION"
echo "Cluster ECS: $CLUSTER_NAME"

# ==============================
# Obter VPC Default
# ==============================
VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --region $AWS_REGION \
  --query "Vpcs[0].VpcId" \
  --output text)

echo "VPC Default: $VPC_ID"

# ==============================
# Obter Subnet Default
# ==============================
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=$VPC_ID \
  --region $AWS_REGION \
  --query "Subnets[0].SubnetId" \
  --output text)

echo "Subnet: $SUBNET_ID"

# ==============================
# Criar Security Group (se não existir)
# ==============================
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=$SECURITY_GROUP_NAME Name=vpc-id,Values=$VPC_ID \
  --region $AWS_REGION \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "")

if [[ -z "$SG_ID" || "$SG_ID" == "None" ]]; then
  echo "➕ Criando Security Group"
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "ECS Security Group" \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --query "GroupId" \
    --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION

  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 8080-8090 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION

  echo "✅ Security Group criado: $SG_ID"
else
  echo "✔ Security Group já existe: $SG_ID"
fi

# ==============================
# Obter AMI ECS-Optimized
# ==============================
AMI_ID=$(aws ssm get-parameter \
  --name /aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id \
  --region $AWS_REGION \
  --query "Parameter.Value" \
  --output text)

echo "AMI ECS Optimized: $AMI_ID"

# ==============================
# User Data
# ==============================
USER_DATA=$(cat <<EOF
#!/bin/bash
echo ECS_CLUSTER=$CLUSTER_NAME >> /etc/ecs/ecs.config
EOF
)

# ==============================
# Criar EC2
# ==============================
echo "🚀 Criando instância EC2 ECS"
aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --user-data "$USER_DATA" \
  --region $AWS_REGION \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[
    {Key=Project,Value=infra-aws-free-tier},
    {Key=Name,Value=ecs-app-instance}
  ]'



echo "✅ EC2 criada com sucesso"
