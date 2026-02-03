#!/bin/bash
set -e

# Update system
yum update -y
yum install -y docker git ruby wget

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

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
  --env-file /etc/starttech/config.env \
  $FULL_IMAGE

# Send custom metric to CloudWatch
aws cloudwatch put-metric-data \
  --metric-name InstanceStartup \
  --namespace StartTech/Backend \
  --value 1 \
  --region ${aws_region}
