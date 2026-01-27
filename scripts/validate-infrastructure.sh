#!/bin/bash

# Validate Infrastructure
# Runs security and compliance checks on Terraform configuration

set -e

TF_DIR="terraform"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Running infrastructure validation...${NC}"

# Check if Terraform files exist
if [ ! -d "$TF_DIR" ]; then
    echo -e "${RED}❌ Terraform directory not found: $TF_DIR${NC}"
    exit 1
fi

# 1. Format Check
echo -e "\n${BLUE}1️⃣  Checking Terraform formatting...${NC}"
cd "$TF_DIR"
if terraform fmt -check -recursive; then
    echo -e "${GREEN}✅ All Terraform files are properly formatted${NC}"
else
    echo -e "${RED}❌ Terraform files need formatting${NC}"
    echo "Run: terraform fmt -recursive"
    exit 1
fi

# 2. Validation
echo -e "\n${BLUE}2️⃣  Validating Terraform configuration...${NC}"
if terraform validate; then
    echo -e "${GREEN}✅ Terraform configuration is valid${NC}"
else
    echo -e "${RED}❌ Terraform configuration is invalid${NC}"
    exit 1
fi

# 3. TFLint
echo -e "\n${BLUE}3️⃣  Running TFLint checks...${NC}"
if command -v tflint &> /dev/null; then
    tflint --init
    if tflint -f compact; then
        echo -e "${GREEN}✅ TFLint checks passed${NC}"
    else
        echo -e "${YELLOW}⚠️  TFLint found issues (non-critical)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  TFLint not installed. Skipping...${NC}"
fi

# 4. TFSec
echo -e "\n${BLUE}4️⃣  Running TFSec security checks...${NC}"
if command -v tfsec &> /dev/null; then
    if tfsec . -f json -o tfsec-report.json --minimum-severity MEDIUM 2>/dev/null; then
        echo -e "${GREEN}✅ No critical security issues found${NC}"
    else
        if tfsec . --minimum-severity HIGH; then
            echo -e "${YELLOW}⚠️  TFSec found medium-severity issues${NC}"
        else
            echo -e "${RED}❌ TFSec found critical issues${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠️  TFSec not installed. Skipping...${NC}"
fi

# 5. Check for required files
echo -e "\n${BLUE}5️⃣  Checking for required configuration files...${NC}"
REQUIRED_FILES=("main.tf" "variables.tf" "outputs.tf" "terraform.tfvars")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All required files present${NC}"
else
    echo -e "${RED}❌ Missing files: ${MISSING_FILES[*]}${NC}"
    exit 1
fi

# 6. Check for sensitive data
echo -e "\n${BLUE}6️⃣  Checking for sensitive data in code...${NC}"
SENSITIVE_PATTERNS=("password" "secret" "api_key" "private_key" "access_token")
FOUND_SECRETS=0

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -ri "= \".*$pattern.*\"" . --include="*.tf" --include="*.tfvars" 2>/dev/null | grep -v "tfvars.example" | grep -v "placeholder"; then
        echo -e "${YELLOW}⚠️  Found potential secret: $pattern${NC}"
        FOUND_SECRETS=$((FOUND_SECRETS + 1))
    fi
done

if [ $FOUND_SECRETS -eq 0 ]; then
    echo -e "${GREEN}✅ No hardcoded secrets found${NC}"
else
    echo -e "${YELLOW}⚠️  Found $FOUND_SECRETS potential secrets - use variables/secrets manager${NC}"
fi

cd ..

# Final summary
echo -e "\n${BLUE}📋 Validation Summary${NC}"
echo -e "${GREEN}✅ All infrastructure validations completed${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review and update terraform.tfvars"
echo "2. Run: ./scripts/deploy-infrastructure.sh [env] plan"
echo "3. Review the plan output"
echo "4. Run: ./scripts/deploy-infrastructure.sh [env] apply"
