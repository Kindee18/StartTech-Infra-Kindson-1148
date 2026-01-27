#!/bin/bash

# Infrastructure Deployment Script
# Usage: ./scripts/deploy-infrastructure.sh [dev|staging|prod] [plan|apply|destroy]

set -e

ENVIRONMENT="${1:-dev}"
ACTION="${2:-plan}"
AWS_REGION="us-east-1"
TF_DIR="terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo "Usage: $0 [dev|staging|prod] [plan|apply|destroy]"
    exit 1
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo -e "${RED}❌ Invalid action: $ACTION${NC}"
    echo "Usage: $0 [dev|staging|prod] [plan|apply|destroy]"
    exit 1
fi

# Load environment variables
if [ -f ".env.${ENVIRONMENT}" ]; then
    echo -e "${BLUE}📦 Loading environment variables from .env.${ENVIRONMENT}${NC}"
    export $(cat ".env.${ENVIRONMENT}" | grep -v '#' | xargs)
fi

# Check if terraform.tfvars exists
if [ ! -f "${TF_DIR}/terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  terraform.tfvars not found${NC}"
    echo "Creating from example..."
    cp "${TF_DIR}/terraform.tfvars.example" "${TF_DIR}/terraform.tfvars"
    echo -e "${YELLOW}⚠️  Please update terraform.tfvars with your values${NC}"
    exit 1
fi

# Initialize Terraform
echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
cd "${TF_DIR}"

terraform init \
    -backend-config="bucket=${TERRAFORM_STATE_BUCKET}" \
    -backend-config="key=starttech/${ENVIRONMENT}/terraform.tfstate" \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="encrypt=true" \
    -backend-config="dynamodb_table=${TERRAFORM_LOCKS_TABLE}"

# Validate Terraform
echo -e "${BLUE}✅ Validating Terraform configuration...${NC}"
terraform validate

# Format check
echo -e "${BLUE}🎨 Checking Terraform formatting...${NC}"
if ! terraform fmt -check -recursive; then
    echo -e "${YELLOW}⚠️  Terraform files need formatting. Running terraform fmt...${NC}"
    terraform fmt -recursive
fi

# Run action
case "$ACTION" in
    plan)
        echo -e "${BLUE}📋 Running Terraform plan for ${ENVIRONMENT}...${NC}"
        terraform plan \
            -var-file="terraform.tfvars" \
            -var="environment=${ENVIRONMENT}" \
            -out="${ENVIRONMENT}.tfplan"
        echo -e "${GREEN}✅ Plan saved to ${ENVIRONMENT}.tfplan${NC}"
        ;;
    apply)
        echo -e "${BLUE}🚀 Applying Terraform for ${ENVIRONMENT}...${NC}"
        if [ ! -f "${ENVIRONMENT}.tfplan" ]; then
            echo -e "${RED}❌ Plan file ${ENVIRONMENT}.tfplan not found${NC}"
            echo "Run 'plan' action first: $0 ${ENVIRONMENT} plan"
            exit 1
        fi
        terraform apply -input=false "${ENVIRONMENT}.tfplan"
        echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
        terraform output -json > "${ENVIRONMENT}-outputs.json"
        echo -e "${GREEN}✅ Outputs saved to ${ENVIRONMENT}-outputs.json${NC}"
        ;;
    destroy)
        echo -e "${RED}🔥 Destroying Terraform resources for ${ENVIRONMENT}...${NC}"
        read -p "Are you sure you want to destroy the ${ENVIRONMENT} infrastructure? Type 'yes' to confirm: " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Destruction cancelled."
            exit 0
        fi
        terraform destroy -var="environment=${ENVIRONMENT}" -var-file="terraform.tfvars"
        echo -e "${GREEN}✅ Infrastructure destroyed${NC}"
        ;;
esac

cd ..

echo -e "${GREEN}✅ Done!${NC}"
