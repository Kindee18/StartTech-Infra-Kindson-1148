#!/bin/bash
set -e

# Update system
yum update -y
yum install -y docker git

# Start Docker
systemctl start docker
systemctl enable docker

# Create log group if it doesn't exist
aws logs create-log-group --log-group-name ${log_group_name} --region ${aws_region} 2>/dev/null || true

# Pull and run Docker container
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin $(echo ${docker_image} | cut -d'/' -f1)

docker run -d \
  --name starttech-backend \
  --restart always \
  -p ${backend_port}:${backend_port} \
  -e ENVIRONMENT=${environment} \
  -e PORT=${backend_port} \
  -e REDIS_URL=${redis_endpoint} \
  -e MONGODB_URI=${mongodb_connection_string} \
  -v /var/log:/var/log \
  --log-driver awslogs \
  --log-opt awslogs-group=${log_group_name} \
  --log-opt awslogs-region=${aws_region} \
  --log-opt awslogs-stream=backend \
  ${docker_image}

# Send custom metric to CloudWatch
aws cloudwatch put-metric-data \
  --metric-name ContainerStartup \
  --namespace StartTech/Backend \
  --value 1 \
  --region ${aws_region}
