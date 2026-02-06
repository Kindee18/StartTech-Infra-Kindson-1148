# Infrastructure Workflows - Complete Setup

## 🎯 Overview

Three Terraform CI/CD workflows manage your infrastructure:

### 1. **Validate Workflow** (terraform-validate.yml)

Runs on pull requests to validate code quality and security.

**Triggers:**

- Pull requests to `main` branch with terraform changes
- Manual dispatch

**Jobs:**

- ✅ Terraform Format Check
- ✅ TFLint (linting)
- ✅ TFSec (security scanning)
- ✅ PR Comments with findings

### 2. **Deploy Workflow** (terraform-deploy.yml)

Plans and applies infrastructure changes.

**Triggers:**

- Push to `main` branch with terraform changes
- Pull requests to `main`
- Manual dispatch with action options

**Jobs:**

1. **Terraform Plan**
   - Format validation
   - Terraform init with remote state
   - Terraform validate
   - Terraform plan
   - Uploads plan artifact
   - Comments PR with change summary

2. **Terraform Apply** (only on main branch push)
   - Retrieves plan artifact
   - Applies changes
   - Exports outputs to artifact
   - Sends Slack notification

### 3. **Destroy Workflow** (terraform-destroy.yml)

Safely destroys infrastructure with confirmation.

**Triggers:**

- Manual dispatch only (safety)

**Inputs:**

- Environment: dev, staging, or prod
- Confirm: Type "YES" to confirm

**Jobs:**

- Plan destruction
- Apply destruction with auto-approval
- Send Slack notification

## ✅ Secrets Configured (11 total)

### AWS & Terraform

- `AWS_ACCOUNT_ID` = 125168806853
- `TERRAFORM_ROLE_NAME` = dev-github-infra-role
- `TERRAFORM_STATE_BUCKET` = dev-starttech-terraform-state-125168806853
- `TERRAFORM_LOCKS_TABLE` = dev-starttech-terraform-locks

### Application

- `ECR_REPOSITORY_URL` = 125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend
- `ENVIRONMENT` = dev

### MongoDB Atlas (⚠️ Requires Manual Update)

- `MONGODB_USERNAME` = starttech_app
- `MONGODB_PASSWORD` = **CHANGE_ME** (set in GitHub)
- `MONGODB_ORG_ID` = **CHANGE_ME** (set in GitHub)
- `MONGODB_PUBLIC_KEY` = **CHANGE_ME** (set in GitHub)
- `MONGODB_PRIVATE_KEY` = **CHANGE_ME** (set in GitHub)

## ⚠️ Manual Configuration Required

### Step 1: Get MongoDB Atlas Credentials

1. Go to MongoDB Atlas: https://cloud.mongodb.com
2. Navigate to **API Keys** section in your organization
3. Create a new API Key or use existing
4. Copy:
   - Organization ID (ORG_ID)
   - Public Key
   - Private Key

### Step 2: Update GitHub Secrets

1. Go to: https://github.com/Kindee18/StartTech-Infra-Kindson-1148/settings/secrets/actions
2. Edit each secret:
   - `MONGODB_ORG_ID` - Paste organization ID
   - `MONGODB_PUBLIC_KEY` - Paste public key
   - `MONGODB_PRIVATE_KEY` - Paste private key
   - `MONGODB_PASSWORD` - Your MongoDB database password

## 🚀 How to Deploy Infrastructure

### Option 1: Automatic Deploy (on push)

```bash
cd /home/kindson/StartTech-Infra-Kindson-1148
git add terraform/
git commit -m "Update infrastructure"
git push origin main
```

Workflow will:

1. Run validation on PR (if applicable)
2. Auto-apply when merged to main
3. Send Slack notification

### Option 2: Manual Deploy (workflow_dispatch)

1. Go to: https://github.com/Kindee18/StartTech-Infra-Kindson-1148/actions
2. Select "Infrastructure Deployment"
3. Click "Run workflow"
4. Select action:
   - `plan` - Shows what would change (default)
   - `apply` - Applies the changes
   - `destroy` - Destroys infrastructure

### Option 3: Destroy Infrastructure

```
⚠️ CAREFUL - This deletes your infrastructure!
```

1. Go to: https://github.com/Kindee18/StartTech-Infra-Kindson-1148/actions
2. Select "Destroy Infrastructure"
3. Choose environment (dev/staging/prod)
4. Type "YES" to confirm
5. Click "Run workflow"

## 📊 Monitoring Deployments

### GitHub Actions

- **All Workflows**: https://github.com/Kindee18/StartTech-Infra-Kindson-1148/actions
- **Validate**: https://github.com/Kindee18/StartTech-Infra-Kindson-1148/actions/workflows/terraform-validate.yml
- **Deploy**: https://github.com/Kindee18/StartTech-Infra-Kindson-1148/actions/workflows/terraform-deploy.yml
- **Destroy**: https://github.com/Kindee18/StartTech-Infra-Kindson-1148/actions/workflows/terraform-destroy.yml

### Terraform State

```bash
cd terraform

# View current state
terraform state list

# Check specific resource
terraform state show aws_instance.backend

# View outputs
terraform output

# Export all outputs
terraform output -json > outputs.json
```

### CloudWatch Dashboard

https://console.aws.amazon.com/cloudwatch/home#dashboards:name=dev-starttech-dashboard

## 🔍 Troubleshooting

### "Authentication failed" Error

- Verify `AWS_ACCOUNT_ID` and `TERRAFORM_ROLE_NAME` are correct
- Check OIDC provider exists in AWS IAM
- Ensure IAM role trust policy allows GitHub Actions

### "State lock timeout" Error

- Check if another deployment is running
- Manually unlock: `terraform force-unlock <LOCK_ID>`

### "Resource already exists" Error

- Check current state: `terraform state list`
- Import existing resource: `terraform import aws_instance.name i-1234567890`

### Plan shows no changes but apply fails

- Run `terraform refresh` to sync state
- Check for manual AWS resource changes
- Review CloudWatch logs



## 📋 Best Practices

### Before Making Changes

1. Create a feature branch
2. Update terraform files
3. Push to GitHub (triggers validation)
4. Review linting and security findings in PR
5. Fix issues if any
6. Merge to main

### Planning Deployments

```bash
# Local plan before commit
cd terraform
terraform plan -out=tfplan

# Review changes
terraform show tfplan

# Push only if changes look good
git push origin feature-branch
```

### State Management

```bash
# Always use remote state
terraform init

# Backup state before major changes
aws s3 cp s3://dev-starttech-terraform-state-125168806853/starttech/terraform.tfstate ./terraform.tfstate.backup

# View who made changes
aws dynamodb get-item \
  --table-name dev-starttech-terraform-locks \
  --key '{"ID":{"S":"starttech/terraform.tfstate"}}'
```

### Security

- ✅ Use OIDC authentication (no long-lived credentials)
- ✅ Encrypt terraform state (S3 + DynamoDB)
- ✅ Use secrets for sensitive values (passwords, keys)
- ✅ Review TFSec findings for security issues
- ✅ Use workspace to separate environments

## 📚 Related Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Application deployment
- [RUNBOOK.md](RUNBOOK.md) - Operations procedures
- [README.md](README.md) - Infrastructure overview
- [terraform/variables.tf](terraform/variables.tf) - Variable definitions
- [terraform/outputs.tf](terraform/outputs.tf) - Output definitions

## 🔧 Configuration Scripts

### Reconfigure Secrets Anytime

```bash
cd /home/kindson/StartTech-Infra-Kindson-1148
./configure-infra-secrets.sh
```

### Get Latest Outputs

```bash
cd terraform
terraform output -json > terraform-outputs.json

# Share with team
cat terraform-outputs.json | jq .
```

---

**Last Updated**: 2026-01-31

**Status**: ✅ Ready for infrastructure deployments
