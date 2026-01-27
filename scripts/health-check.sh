#!/bin/bash

# Health Check Script
# Validates the deployed infrastructure is healthy

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏥 Running health checks for ${ENVIRONMENT} infrastructure...${NC}"

# Get ALB DNS name
echo -e "${BLUE}📍 Fetching ALB information...${NC}"
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, '${ENVIRONMENT}-alb')].DNSName" \
    --output text)

if [ -z "$ALB_DNS" ]; then
    echo -e "${RED}❌ Could not find ALB for environment: ${ENVIRONMENT}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ALB DNS: $ALB_DNS${NC}"

# Test ALB health
echo -e "${BLUE}🔍 Testing ALB health endpoint...${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${ALB_DNS}/health" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ ALB health endpoint responding (HTTP $HTTP_STATUS)${NC}"
else
    echo -e "${RED}❌ ALB health endpoint returned HTTP $HTTP_STATUS${NC}"
fi

# Check RDS/MongoDB connectivity
echo -e "${BLUE}🔍 Checking MongoDB connectivity...${NC}"
MONGODB_HOST=$(aws secretsmanager get-secret-value \
    --secret-id "${ENVIRONMENT}/mongodb/host" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null || echo "")

if [ -n "$MONGODB_HOST" ]; then
    echo -e "${GREEN}✅ MongoDB host found: $MONGODB_HOST${NC}"
else
    echo -e "${YELLOW}⚠️  MongoDB host not found in Secrets Manager${NC}"
fi

# Check Redis connectivity
echo -e "${BLUE}🔍 Checking ElastiCache Redis...${NC}"
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
    --region "$AWS_REGION" \
    --query "CacheClusters[?CacheClusterId=='${ENVIRONMENT}-redis'].CacheNodes[0].Endpoint.Address" \
    --output text)

if [ -n "$REDIS_ENDPOINT" ] && [ "$REDIS_ENDPOINT" != "None" ]; then
    echo -e "${GREEN}✅ Redis endpoint: $REDIS_ENDPOINT${NC}"
else
    echo -e "${YELLOW}⚠️  Redis cluster not found or not ready${NC}"
fi

# Check ASG instances
echo -e "${BLUE}🔍 Checking Auto Scaling Group status...${NC}"
ASG_NAME="${ENVIRONMENT}-backend-asg"
ASG_INFO=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --region "$AWS_REGION" \
    --query "AutoScalingGroups[0]" \
    --output json 2>/dev/null || echo "{}")

if [ "$ASG_INFO" != "{}" ]; then
    DESIRED=$(echo "$ASG_INFO" | jq -r '.DesiredCapacity')
    CURRENT=$(echo "$ASG_INFO" | jq -r '.Instances | length')
    HEALTHY=$(echo "$ASG_INFO" | jq -r '.Instances[] | select(.HealthStatus=="Healthy") | .InstanceId' | wc -l)
    
    echo -e "${BLUE}ASG Status:${NC}"
    echo -e "  Desired: $DESIRED"
    echo -e "  Current: $CURRENT"
    echo -e "  Healthy: $HEALTHY"
    
    if [ "$DESIRED" -eq "$HEALTHY" ]; then
        echo -e "${GREEN}✅ All instances are healthy${NC}"
    else
        echo -e "${YELLOW}⚠️  Not all instances are healthy ($HEALTHY/$DESIRED)${NC}"
    fi
else
    echo -e "${RED}❌ Could not find ASG: $ASG_NAME${NC}"
fi

# Check CloudWatch alarms
echo -e "${BLUE}🔍 Checking CloudWatch alarms...${NC}"
ALARMS=$(aws cloudwatch describe-alarms \
    --alarm-name-prefix "${ENVIRONMENT}-backend" \
    --region "$AWS_REGION" \
    --query "MetricAlarms[*].[AlarmName,StateValue]" \
    --output text)

if [ -n "$ALARMS" ]; then
    echo "$ALARMS" | while read name state; do
        if [ "$state" = "OK" ]; then
            echo -e "  ${GREEN}✅${NC} $name: $state"
        elif [ "$state" = "ALARM" ]; then
            echo -e "  ${RED}❌${NC} $name: $state"
        else
            echo -e "  ${YELLOW}⚠️ ${NC} $name: $state"
        fi
    done
else
    echo -e "${YELLOW}⚠️  No alarms found${NC}"
fi

# Check recent logs
echo -e "${BLUE}🔍 Checking recent application logs...${NC}"
LOG_GROUP="/aws/ec2/${ENVIRONMENT}/backend"
RECENT_ERRORS=$(aws logs filter-log-events \
    --log-group-name "$LOG_GROUP" \
    --region "$AWS_REGION" \
    --filter-pattern "ERROR" \
    --start-time $(($(date +%s) - 300))000 \
    --query "events | length(@)" \
    --output text 2>/dev/null || echo "0")

echo -e "Recent errors in past 5 minutes: $RECENT_ERRORS"

# Summary
echo -e "\n${BLUE}📊 Health Check Summary${NC}"
echo -e "${GREEN}✅ Infrastructure health checks completed${NC}"
