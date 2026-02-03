#!/bin/bash
set -e

# Update system
yum update -y
yum install -y docker git ruby wget

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install CodeDeploy Agent
cd /home/ec2-user
wget https://aws-codedeploy-${aws_region}.s3.${aws_region}.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# Create log group if it doesn't exist
aws logs create-log-group --log-group-name ${log_group_name} --region ${aws_region} 2>/dev/null || true

# Extract ECR details from the docker_image variable
FULL_IMAGE="${docker_image}"
ECR_REGISTRY=$(echo $FULL_IMAGE | cut -d'/' -f1)
# Get the repository name (everything after registry/ and before :tag)
REPO_AND_TAG=$(echo $FULL_IMAGE | cut -d'/' -f2-)
ECR_REPOSITORY=$(echo $REPO_AND_TAG | cut -d':' -f1)

# Create config file for CodeDeploy scripts
mkdir -p /etc/starttech
cat <<EOF > /etc/starttech/config.env
export ENVIRONMENT=${environment}
export PORT=${backend_port}
export ECR_REGISTRY=$ECR_REGISTRY
export ECR_REPOSITORY=$ECR_REPOSITORY
export REDIS_ADDR=${redis_endpoint}
export MONGODB_URI=${mongodb_connection_string}
export JWT_SECRET_KEY=${jwt_secret_key}
export JWT_EXPIRATION_HOURS=72
export AWS_REGION=${aws_region}
export LOG_GROUP_NAME=${log_group_name}
EOF

# Make it readable
chmod 644 /etc/starttech/config.env

# Send custom metric to CloudWatch
aws cloudwatch put-metric-data \
  --metric-name InstanceStartup \
  --namespace StartTech/Backend \
  --value 1 \
  --region ${aws_region}
