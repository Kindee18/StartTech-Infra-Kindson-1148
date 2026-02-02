#!/bin/bash

# Infrastructure Rollback Script
# Usage: ./scripts/rollback.sh [dev|staging|prod] [plan-file-path]

set -e

ENVIRONMENT="${1:-dev}"
PLAN_FILE="${2:-}"
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
    echo "Usage: $0 [dev|staging|prod] [plan-file-path]"
    exit 1
fi

echo -e "${YELLOW}⚠️  Infrastructure Rollback for ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}This will attempt to rollback to a previous Terraform state${NC}"
read -p "Are you sure you want to proceed? Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

# Load environment variables
if [ -f ".env.${ENVIRONMENT}" ]; then
    echo -e "${BLUE}📦 Loading environment variables from .env.${ENVIRONMENT}${NC}"
    export $(cat ".env.${ENVIRONMENT}" | grep -v '#' | xargs)
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

# Check if we have a previous state backup
STATE_BACKUP="${ENVIRONMENT}-terraform.tfstate.backup"
if [ -f "${STATE_BACKUP}" ]; then
    echo -e "${BLUE}📦 Found state backup: ${STATE_BACKUP}${NC}"
    echo -e "${YELLOW}⚠️  Restoring from backup...${NC}"
    
    # Create a backup of current state
    if [ -f "terraform.tfstate" ]; then
        cp terraform.tfstate "terraform.tfstate.rollback-backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Restore from backup
    cp "${STATE_BACKUP}" terraform.tfstate
    
    echo -e "${BLUE}📋 Planning rollback...${NC}"
    terraform plan \
        -var-file="terraform.tfvars" \
        -var="environment=${ENVIRONMENT}" \
        -out="${ENVIRONMENT}-rollback.tfplan"
    
    read -p "Review the plan above. Apply rollback? Type 'yes' to confirm: " apply_confirm
    if [ "$apply_confirm" == "yes" ]; then
        terraform apply -input=false "${ENVIRONMENT}-rollback.tfplan"
        echo -e "${GREEN}✅ Rollback completed successfully!${NC}"
    else
        echo "Rollback cancelled."
        exit 0
    fi
elif [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
    echo -e "${BLUE}📦 Using provided plan file: ${PLAN_FILE}${NC}"
    echo -e "${YELLOW}⚠️  Applying rollback plan...${NC}"
    terraform apply -input=false "$PLAN_FILE"
    echo -e "${GREEN}✅ Rollback completed successfully!${NC}"
else
    echo -e "${RED}❌ No rollback plan or state backup found${NC}"
    echo "Options:"
    echo "  1. Provide a previous plan file: $0 ${ENVIRONMENT} /path/to/plan.tfplan"
    echo "  2. Restore from S3 state backup manually"
    echo "  3. Use terraform state commands to rollback specific resources"
    exit 1
fi

cd ..

echo -e "${GREEN}✅ Rollback complete!${NC}"
