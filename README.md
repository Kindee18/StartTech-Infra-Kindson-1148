# StartTech Infrastructure as Code


> [!NOTE]
> **Deployment Status**: Use of live resources (ALB, RDS, CloudFront) has been suspended to avoid ongoing AWS costs.
>
> **To Redeploy (Restore System):**
> 1. **(If destroyed)** Run `./scripts/restore-oidc.sh` locally to restore AWS access for GitHub.
> 2. Run [Infrastructure Deployment](.github/workflows/infrastructure-deploy.yml) workflow (creates servers/DBs).
> 3. Run [Backend CI/CD](https://github.com/Kindee18/StartTech-Kindson-1148/blob/main/.github/workflows/backend-ci-cd.yml) workflow (builds Docker image & pushes to ECR).
> 4. Run [Frontend CI/CD](https://github.com/Kindee18/StartTech-Kindson-1148/blob/main/.github/workflows/frontend-ci-cd.yml) workflow (builds React app & uploads to S3).

Complete Terraform-based infrastructure for the StartTech full-stack application with AWS deployment, CI/CD automation, and comprehensive monitoring.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Directory Structure](#directory-structure)
4. [Key Directories](#key-directories)
5. [Deployment Guide (Zero to Hero)](#deployment-guide-zero-to-hero)
6. [Destruction Guide](#destruction-guide-cost-saving)
7. [Helper Scripts](#helper-scripts)
8. [Monitoring & Logging](#monitoring)
9. [GitHub OIDC Setup](#github-oidc)
10. [Troubleshooting](#troubleshooting)
11. [Security](#security)
12. [Cost Optimization](#cost-optimization)

## 🏗️ Architecture Overview

The infrastructure includes:

- **VPC with High Availability**: Multi-AZ deployment with public and private subnets
- **Application Load Balancer**: Distributes traffic to EC2 instances
- **Auto Scaling Group**: EC2 instances with automatic scaling based on CPU utilization
- **MongoDB**: MongoDB Atlas managed database service
- **ElastiCache**: Redis cluster for caching and sessions
- **S3 + CloudFront**: Static frontend hosting with CDN
- **CloudWatch**: Centralized logging and monitoring
- **IAM OIDC**: GitHub Actions integration without storing secrets

## 📋 Prerequisites

### Software

- Terraform >= 1.0
- AWS CLI v2
- Git, Docker, jq

### AWS Requirements

- AWS account with appropriate IAM permissions
- S3 bucket for Terraform state
- DynamoDB table for state locking
- GitHub account with admin access

## 📁 Key Directories

```
terraform/              # Terraform root configuration
├── main.tf            # Root module
├── variables.tf       # Input variables
├── outputs.tf         # Outputs
└── modules/
    ├── networking/    # VPC, subnets, security groups
    ├── compute/       # ALB, ASG, EC2
    ├── storage/       # S3, CloudFront
    ├── database/      # MongoDB Atlas
    ├── caching/       # ElastiCache Redis
    ├── monitoring/    # CloudWatch
    └── iam/           # IAM roles, OIDC

.github/workflows/      # GitHub Actions
├── infrastructure-deploy.yml
├── terraform-validate.yml
└── terraform-destroy.yml

scripts/                # Deployment scripts
├── deploy-infrastructure.sh
├── validate-infrastructure.sh
├── health-check.sh
├── rollback.sh
├── restore-oidc.sh     # Restore GitHub access
└── nuke-s3.sh          # Cleanup S3 buckets

monitoring/             # Monitoring config
├── cloudwatch-dashboard.json
├── alarm-definitions.json
└── log-insights-queries.txt
```

## 🚀 Deployment Guide (Zero to Hero)

### 1. Prerequisites
- **AWS Account**: You need an AWS account with Admin permissions.
- **GitHub Secrets**: Ensure `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set in this repo for the OIDC Bootstrap (first run only) or local usage.
- **Terraform State**: The bootstrap process (or manual setup) must create the S3 bucket (`dev-starttech-terraform-state-...`) and DynamoDB table.

### 2. Redeploying from Scratch (The "Wake Up" Protocol)
If the infrastructure has been destroyed, you must restore the OIDC link before GitHub Actions can work.

**Step 0: Restore OIDC (Local Terminal)**
```bash
# From the root of this repo
./scripts/restore-oidc.sh
```
*This re-establishes the trust between GitHub and your AWS account.*

**Step 1: Provision Infrastructure (GitHub Actions)**
1. Go to **Actions** tab.
2. Select **Infrastructure Deployment**.
3. Click **Run workflow** -> Select `main` branch -> **Run workflow**.
4. Wait for completion (creates VPC, ALB, ASG, RDS, ElastiCache, S3, CloudFront).

**Step 2: Deploy Application (Application Repo)**
Once infrastructure is ready, go to the [Application Repository](https://github.com/Kindee18/StartTech-Kindson-1148) and run its pipelines:
1. **Backend CI/CD**: Builds Docker image, pushes to ECR, updates ASG.
2. **Frontend CI/CD**: Builds React app, syncs to S3, invalidates CloudFront.

---

## 💥 Destruction Guide (Cost Saving)

To pause the project and stop paying for resources (~$172/mo), adhere to this process.

### Method 1: Automated Destruction (Recommended)
1. Go to **Actions** tab in this repository.
2. Select **Destroy Infrastructure** workflow.
3. Click **Run workflow**.
4. **Input Required**:
   - Environment: `dev`
   - Confirmation: `YES`
5. Run the workflow. It will automatically wipe all resources including S3 buckets and ECR repositories.

### Method 2: Manual Destruction (Fallback)
If GitHub Actions fails (e.g., OIDC issues), run this locally:

```bash
cd terraform
# Ensure you have AWS credentials exported in your terminal
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

# Run Destroy
terraform init
terraform destroy -auto-approve -var-file="secrets.auto.tfvars"
```

### ⚠️ Troubleshooting Destruction
- **"BucketNotEmpty"**: If S3 destroy fails, run: `scripts/nuke-s3.sh` locally.
- **"No OpenIDConnect provider"**: Run `scripts/restore-oidc.sh` locally, then retry Method 1.

---

## 🛠 Helper Scripts

The `scripts/` directory contains utilities to simplify management.

| Script | Purpose | Usage |
|--------|---------|-------|
| `restore-oidc.sh` | **Essential.** Restores GitHub access after a destroy. | `./scripts/restore-oidc.sh` |
| `nuke-s3.sh` | Force-cleans stubborn S3 buckets (versions). | `./scripts/nuke-s3.sh` |
| `deploy-infrastructure.sh` | Wrapper for Terraform plan/apply with checks. | `./scripts/deploy-infrastructure.sh dev plan` |
| `validate-infrastructure.sh` | Runs `terraform validate`, `tflint`, and security scans. | `./scripts/validate-infrastructure.sh` |
| `health-check.sh` | Verifies endpoints (ALB, DB) are responding. | `./scripts/health-check.sh https://api.example.com` |
| `rollback.sh` | Reverts Infrastructure or App to previous state. | `./scripts/rollback.sh backend production <ID>` |
| `final-cleanup.sh` | Deep clean of local logs and temporary files. | `./scripts/final-cleanup.sh` |

> **Note:** Always run scripts from the repository root. Ensure they are executable (`chmod +x scripts/*.sh`).

---

---

## 🛠 Helper Scripts

The `scripts/` directory contains utilities to simplify management.

| Script | Purpose | Usage |
|--------|---------|-------|
| `restore-oidc.sh` | **Essential.** Restores GitHub access after a destroy. | `./scripts/restore-oidc.sh` |
| `nuke-s3.sh` | Force-cleans stubborn S3 buckets (versions). | `./scripts/nuke-s3.sh` |
| `deploy-infrastructure.sh` | Wrapper for Terraform plan/apply with checks. | `./scripts/deploy-infrastructure.sh dev plan` |
| `validate-infrastructure.sh` | Runs `terraform validate`, `tflint`, and security scans. | `./scripts/validate-infrastructure.sh` |
| `health-check.sh` | Verifies endpoints (ALB, DB) are responding. | `./scripts/health-check.sh https://api.example.com` |
| `rollback.sh` | Reverts Infrastructure or App to previous state. | `./scripts/rollback.sh backend production <ID>` |
| `final-cleanup.sh` | Deep clean of local logs and temporary files. | `./scripts/final-cleanup.sh` |

> **Note:** Always run scripts from the repository root. Ensure they are executable (`chmod +x scripts/*.sh`).

## 📊 Monitoring

- **CloudWatch Dashboards**: Automatic creation for all metrics
- **Alarms**: CPU, memory, response time, errors
- **Log Groups**: `/aws/ec2/{env}/backend`, `/aws/alb/{env}`, ElastiCache logs
- **Queries**: See [monitoring/log-insights-queries.txt](monitoring/log-insights-queries.txt)

## 🔐 GitHub OIDC

OIDC provider automatically created by Terraform. In GitHub Actions:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT_ID:role/dev-github-infra-role
    aws-region: us-east-1
```

## 🔍 Troubleshooting

### Common Issues

1. **Terraform State Lock**: Check DynamoDB lock table
2. **ALB Health Failures**: SSH into instance and check service
3. **EC2 Boot Issues**: Check CloudWatch logs
4. **MongoDB Connection**: Whitelist security group in Atlas
5. **Redis Connection**: Verify security group allows 6379

### Debug Mode

```bash
export TF_LOG=DEBUG
terraform plan
unset TF_LOG
```

## 🔐 Security

### Best Practices

- Use remote state with encryption
- Enable state locking
- Restrict SSH access to specific IPs
- Use AWS Secrets Manager for sensitive data
- Enable CloudTrail for audit logging
- Follow least-privilege IAM principle
- Enable encryption on all storage (S3, RDS, ElastiCache)

### Sensitive Data

- Passwords and keys: Use environment variables
- Don't commit `terraform.tfvars` with real values
- Use `sensitive = true` for secret variables
- Rotate credentials regularly

## 💰 Cost Optimization

Estimated monthly cost (US East):

- ALB: $18
- EC2 (2x t3.medium): $56
- ElastiCache (t3.micro): $16
- MongoDB Atlas (M5): $57
- S3 + CloudFront: $15
- CloudWatch: $10
- **Total: ~$172/month**

### Optimization Tips

- Use Reserved Instances (30-50% savings)
- Mix Spot Instances for non-critical workloads
- Schedule scaling for off-peak hours
- Use appropriate instance sizes

## 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture
- [RUNBOOK.md](RUNBOOK.md) - Operations guide
- [monitoring/log-insights-queries.txt](monitoring/log-insights-queries.txt) - Useful queries

## ✅ First Deployment Checklist

- [ ] AWS account and credentials configured
- [ ] Terraform installed
- [ ] `terraform.tfvars` updated with values
- [ ] S3 bucket for state created
- [ ] DynamoDB table for locks created
- [ ] GitHub OIDC ready (auto-created)
- [ ] Run `terraform validate`
- [ ] Run `terraform plan`
- [ ] Review plan output
- [ ] Run `terraform apply`
- [ ] Run health checks
- [ ] Configure GitHub Actions secrets
- [ ] Test CI/CD pipeline

## 📞 Support

For issues:

1. Check [RUNBOOK.md](RUNBOOK.md) for troubleshooting
2. Review [ARCHITECTURE.md](ARCHITECTURE.md)
3. Check CloudWatch logs
4. Open GitHub issue

## 📄 License

Part of the StartTech project.

## 🔗 Related Repositories

- **Application Repo**: [StartTech-Kindson-1148](https://github.com/Kindee18/StartTech-Kindson-1148)
