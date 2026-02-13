#!/bin/bash
set -e

# StartTech OIDC Restoration Script
# Usage: ./restore-oidc.sh

echo "🔄 Restoring GitHub OIDC Provider..."
echo "This allows GitHub Actions to authenticate with your AWS account."

cd "$(dirname "$0")/../terraform"

# Initialize if needed
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Apply only the IAM module (contains OIDC and Roles)
terraform apply -target=module.iam -auto-approve -var-file="secrets.auto.tfvars"

echo "✅ OIDC Provider Restored!"
echo "You can now run GitHub Actions workflows."
