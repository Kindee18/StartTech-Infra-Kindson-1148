#!/bin/bash
set -e

# Update system
yum update -y
yum install -y docker git ruby wget

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Create config directory
mkdir -p /etc/starttech

# Initialize variables from Terraform template
export ECR_REGISTRY=$(echo "${docker_image}" | cut -d/ -f1)
export FULL_IMAGE="${docker_image}"

# Create environment file
cat <<EOF > /etc/starttech/config.env
ENVIRONMENT=${environment}
PORT=${backend_port}
MONGO_URI=${mongodb_connection_string}
DB_NAME=${mongodb_db_name}
REDIS_ADDR=${redis_endpoint}
ENABLE_CACHE=true
JWT_SECRET_KEY=${jwt_secret_key}
DOCKER_IMAGE=${docker_image}
LOG_GROUP_NAME=${log_group_name}
AWS_REGION=${aws_region}
EOF

# Startup Docker Container
source /etc/starttech/config.env

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull the image
docker pull $FULL_IMAGE

# Run the container
docker run -d \
  --name backend \
  --restart always \
  -p ${backend_port}:${backend_port} \
  -v /etc/starttech/config.env:/root/.env \
  --env-file /etc/starttech/config.env \
  $FULL_IMAGE

# Send custom metric to CloudWatch
aws cloudwatch put-metric-data \
  --metric-name InstanceStartup \
  --namespace StartTech/Backend \
  --value 1 \
  --region ${aws_region}
