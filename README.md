# StartTech Infrastructure as Code

Complete Terraform-based infrastructure for the StartTech full-stack application with AWS deployment, CI/CD automation, and comprehensive monitoring.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Directory Structure](#directory-structure)
4. [Quick Start](#quick-start)
5. [Configuration](#configuration)
6. [Deployment](#deployment)
7. [GitHub OIDC Setup](#github-oidc-setup)
8. [Monitoring & Logging](#monitoring--logging)
9. [Troubleshooting](#troubleshooting)
10. [Security](#security)

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
└── rollback.sh

monitoring/             # Monitoring config
├── cloudwatch-dashboard.json
├── alarm-definitions.json
└── log-insights-queries.txt
```

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/Kindee18/StartTech-Infra-Kindson-1148.git
cd StartTech-Infra-Kindson-1148

# 2. Configure variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars

# 3. Initialize Terraform
cd terraform && terraform init

# 4. Plan deployment
../scripts/deploy-infrastructure.sh dev plan

# 5. Apply
../scripts/deploy-infrastructure.sh dev apply

# 6. Verify
../scripts/health-check.sh dev
```

## ⚙️ Configuration

Key variables in `terraform.tfvars`:

```hcl
aws_region           = "us-east-1"
environment          = "dev"
instance_type        = "t3.medium"
min_size             = 2
max_size             = 6
mongodb_username     = "starttech_app"
mongodb_password     = "your-password"
redis_node_type      = "cache.t3.micro"
docker_image         = "your-account.dkr.ecr.us-east-1.amazonaws.com/backend:latest"
```

## 🚀 Deployment

### Local Deployment

```bash
# Validate
./scripts/validate-infrastructure.sh

# Plan
./scripts/deploy-infrastructure.sh dev plan

# Apply
./scripts/deploy-infrastructure.sh dev apply

# Health check
./scripts/health-check.sh dev
```

### GitHub Actions Deployment

Push to `main` branch triggers:

1. `terraform-validate.yml` - Security checks
2. `terraform-deploy.yml` - Plan and apply

### Multi-Environment

```bash
./scripts/deploy-infrastructure.sh dev apply
./scripts/deploy-infrastructure.sh staging apply
./scripts/deploy-infrastructure.sh prod apply
```

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
