#!/bin/bash
set -e

# StartTech OIDC Restoration Script
# Usage: ./restore-oidc.sh

echo "🔄 Restoring GitHub OIDC Provider (AWS CLI Method)..."
echo "This manual method bypasses Terraform state issues to guarantee access."

# 1. Create OIDC Provider
echo "1️⃣  Creating OIDC Provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd \
  2>/dev/null || echo "   (Provider already exists, continuing...)"

# 2. Create Trust Policy File
echo "2️⃣  Generating Trust Policy..."
cat > trust-policy-temp.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Kindee18/StartTech-Infra-Kindson-1148:ref:refs/heads/main"
        },
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

# 3. Create IAM Role
echo "3️⃣  Creating IAM Role 'dev-github-infra-role'..."
aws iam create-role \
  --role-name dev-github-infra-role \
  --assume-role-policy-document file://trust-policy-temp.json \
  2>/dev/null || \
  aws iam update-assume-role-policy \
  --role-name dev-github-infra-role \
  --policy-document file://trust-policy-temp.json

# 4. Attach Admin Policy
echo "4️⃣  Attaching Permissions..."
aws iam attach-role-policy \
  --role-name dev-github-infra-role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Cleanup
rm trust-policy-temp.json

echo "✅ OIDC Provider & Role Restored!"
echo "GitHub Actions should now have full access."
