#!/bin/bash

# Infrastructure GitHub Secrets Configuration Script
# Configures all required secrets for Terraform CI/CD workflows

set -e

# Repository details
REPO_OWNER="Kindee18"
REPO_NAME="StartTech-Infra-Kindson-1148"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  🔐 Infrastructure Secrets Configuration for Terraform CI/CD   ║"
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
    echo "Install it with:"
    echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "  sudo apt update && sudo apt install gh"
    echo "  gh auth login"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
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

echo "📝 Configuring infrastructure secrets..."
echo ""

# Extract values from terraform outputs
TERRAFORM_STATE_BUCKET=$(get_tf_output "terraform_state_bucket_name")
TERRAFORM_LOCKS_TABLE=$(get_tf_output "terraform_locks_table_name")
ECR_REPOSITORY=$(get_tf_output "ecr_repository_url")

# Static values (from AWS account)
AWS_ACCOUNT_ID="125168806853"
TERRAFORM_ROLE_NAME="dev-github-infra-role"
ENVIRONMENT="dev"

# These need to be provided by user or from secure storage
# For now, we'll create placeholder secrets
MONGODB_PASSWORD="CHANGE_ME_IN_GITHUB_SECRETS"
MONGODB_USERNAME="starttech_app"
MONGODB_ORG_ID="CHANGE_ME_IN_GITHUB_SECRETS"
MONGODB_PUBLIC_KEY="CHANGE_ME_IN_GITHUB_SECRETS"
MONGODB_PRIVATE_KEY="CHANGE_ME_IN_GITHUB_SECRETS"

echo "AWS & Terraform Configuration:"
set_secret "AWS_ACCOUNT_ID" "$AWS_ACCOUNT_ID"
set_secret "TERRAFORM_ROLE_NAME" "$TERRAFORM_ROLE_NAME"
set_secret "TERRAFORM_STATE_BUCKET" "$TERRAFORM_STATE_BUCKET"
set_secret "TERRAFORM_LOCKS_TABLE" "$TERRAFORM_LOCKS_TABLE"
echo ""

echo "Application Configuration:"
set_secret "ECR_REPOSITORY_URL" "$ECR_REPOSITORY"
set_secret "ENVIRONMENT" "$ENVIRONMENT"
echo ""

echo "MongoDB Atlas Configuration (⚠️ Requires Manual Update):"
set_secret "MONGODB_USERNAME" "$MONGODB_USERNAME"
set_secret "MONGODB_PASSWORD" "$MONGODB_PASSWORD"
set_secret "MONGODB_ORG_ID" "$MONGODB_ORG_ID"
set_secret "MONGODB_PUBLIC_KEY" "$MONGODB_PUBLIC_KEY"
set_secret "MONGODB_PRIVATE_KEY" "$MONGODB_PRIVATE_KEY"
echo ""

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  ✅ Configuration Complete                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Summary:"
echo "  • AWS Account: $AWS_ACCOUNT_ID"
echo "  • Terraform State Bucket: $TERRAFORM_STATE_BUCKET"
echo "  • Terraform Locks Table: $TERRAFORM_LOCKS_TABLE"
echo "  • ECR Repository: $ECR_REPOSITORY"
echo ""
echo "⚠️  ACTION REQUIRED:"
echo "  Update these MongoDB secrets in GitHub:"
echo "    1. MONGODB_PASSWORD"
echo "    2. MONGODB_ORG_ID"
echo "    3. MONGODB_PUBLIC_KEY"
echo "    4. MONGODB_PRIVATE_KEY"
echo ""
echo "  Steps:"
echo "    1. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
echo "    2. Edit each secret with actual MongoDB Atlas values"
echo ""
echo "🔍 Verify secrets:"
echo "  gh secret list --repo $REPO_OWNER/$REPO_NAME"
echo ""
echo "🚀 Infrastructure Workflows:"
echo "  • Validation: https://github.com/$REPO_OWNER/$REPO_NAME/actions/workflows/terraform-validate.yml"
echo "  • Deployment: https://github.com/$REPO_OWNER/$REPO_NAME/actions/workflows/terraform-deploy.yml"
echo "  • Destruction: https://github.com/$REPO_OWNER/$REPO_NAME/actions/workflows/terraform-destroy.yml"
echo ""
