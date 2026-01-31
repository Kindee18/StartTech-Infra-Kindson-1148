#!/bin/bash

# GitHub Secrets Configuration Script
# This script configures all required GitHub secrets for CI/CD from Terraform outputs

set -e

# Repository details
REPO_OWNER="Kindee18"
REPO_NAME="StartTech-Kindson-1148"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🔐 GitHub Secrets Configuration for CI/CD                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
TERRAFORM_OUTPUTS="$TERRAFORM_DIR/terraform-outputs.json"

echo -e "${BLUE}Repository:${NC} $REPO_OWNER/$REPO_NAME"
echo -e "${BLUE}Terraform Outputs:${NC} $TERRAFORM_OUTPUTS"
echo ""

# Check if terraform outputs exist
if [ ! -f "$TERRAFORM_OUTPUTS" ]; then
    echo -e "${RED}❌ Terraform outputs file not found: $TERRAFORM_OUTPUTS${NC}"
    echo ""
    echo "Please run the following commands first:"
    echo "  cd $TERRAFORM_DIR"
    echo "  terraform output -json > terraform-outputs.json"
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) is not installed.${NC}"
    echo ""
    echo "To configure secrets, you have two options:"
    echo ""
    echo "1. Install GitHub CLI and run this script:"
    echo "   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "   echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "   sudo apt update && sudo apt install gh"
    echo "   gh auth login"
    echo ""
    echo "2. Manually add secrets via GitHub UI:"
    echo "   https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
    echo ""
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed. Installing...${NC}"
    sudo apt update && sudo apt install -y jq
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Function to extract value from terraform outputs
get_tf_output() {
    local key=$1
    jq -r ".${key}.value // empty" "$TERRAFORM_OUTPUTS"
}

# Function to set secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    
    if [ -z "$secret_value" ] || [ "$secret_value" == "null" ]; then
        echo -e "${YELLOW}⚠️  Skipping $secret_name (no value)${NC}"
        return
    fi
    
    echo -n "  Setting $secret_name... "
    if echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
}

echo "📝 Extracting values from Terraform outputs..."
echo ""

# Extract values
AWS_REGION="us-east-1"
BACKEND_ROLE_ARN=$(get_tf_output "github_backend_role_arn")
FRONTEND_ROLE_ARN=$(get_tf_output "github_frontend_role_arn")
S3_BUCKET=$(get_tf_output "frontend_bucket_name")
CLOUDFRONT_ID=$(get_tf_output "cloudfront_distribution_id")
CLOUDFRONT_DOMAIN=$(get_tf_output "cloudfront_domain_name")
ALB_DNS=$(get_tf_output "alb_dns_name")
ECR_REPO=$(get_tf_output "ecr_repository_url")
REDIS_ENDPOINT=$(get_tf_output "redis_endpoint")

# Construct API base URL
API_BASE_URL="http://${ALB_DNS}"

echo "🔧 Configuring GitHub secrets..."
echo ""

# AWS Configuration
echo "AWS Configuration:"
set_secret "AWS_REGION" "$AWS_REGION"
set_secret "AWS_ROLE_ARN" "$BACKEND_ROLE_ARN"
echo ""

# Frontend Secrets
echo "Frontend Secrets:"
set_secret "S3_BUCKET_STAGING" "$S3_BUCKET"
set_secret "S3_BUCKET_PROD" "$S3_BUCKET"
set_secret "CLOUDFRONT_ID_STAGING" "$CLOUDFRONT_ID"
set_secret "CLOUDFRONT_ID_PROD" "$CLOUDFRONT_ID"
set_secret "API_BASE_URL_STAGING" "$API_BASE_URL"
set_secret "API_BASE_URL_PROD" "$API_BASE_URL"
echo ""

# Backend Secrets
echo "Backend Secrets:"
set_secret "ECR_REPOSITORY_BACKEND" "$ECR_REPO"
set_secret "CODEDEPLOY_APP" "starttech-app"
set_secret "CODEDEPLOY_GROUP_STAGING" "starttech-staging-deployment-group"
set_secret "CODEDEPLOY_GROUP_PROD" "starttech-prod-deployment-group"
set_secret "CODEDEPLOY_S3_BUCKET" "${S3_BUCKET}"
echo ""

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  ✅ Configuration Complete                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Summary:"
echo "  • Frontend Domain: https://${CLOUDFRONT_DOMAIN}"
echo "  • Backend API: ${API_BASE_URL}"
echo "  • ECR Repository: ${ECR_REPO}"
echo "  • S3 Bucket: ${S3_BUCKET}"
echo ""
echo "🔍 Verify secrets:"
echo "  gh secret list --repo $REPO_OWNER/$REPO_NAME"
echo ""
echo "🚀 Next steps:"
echo "  1. Verify secrets in GitHub UI:"
echo "     https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
echo "  2. Push code to trigger CI/CD:"
echo "     git push origin main"
echo "  3. Monitor workflows:"
echo "     https://github.com/$REPO_OWNER/$REPO_NAME/actions"
echo ""
