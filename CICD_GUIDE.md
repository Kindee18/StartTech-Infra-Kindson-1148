# CI/CD Pipeline Implementation Guide

## Overview

This guide provides a comprehensive overview of the CI/CD pipeline implementation for the StartTech infrastructure and application repositories.

## Repository Structure

### StartTech-Infra-Kindson-1148

Infrastructure as Code repository with Terraform modules and CI/CD workflows.

```
├── .github/workflows/
│   ├── terraform-deploy.yml       # Infrastructure deployment automation
│   ├── terraform-validate.yml     # Terraform validation and linting
│   └── terraform-destroy.yml      # Infrastructure teardown (manual trigger)
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Variable definitions
│   ├── outputs.tf                 # Output definitions
│   ├── terraform.tfvars           # Variable values (not in repo)
│   ├── terraform.tfvars.example   # Example variable file
│   └── modules/
│       ├── networking/            # VPC, Subnets, Security Groups
│       ├── compute/               # ALB, ASG, EC2 Launch Template
│       ├── storage/               # S3, CloudFront, Terraform backend
│       ├── caching/               # ElastiCache Redis cluster
│       ├── database/              # MongoDB Atlas or self-hosted
│       ├── monitoring/            # CloudWatch, Logs, Alarms
│       └── iam/                   # IAM roles, policies, OIDC
├── monitoring/
│   ├── cloudwatch-dashboard.json  # CloudWatch dashboard definition
│   ├── alarm-definitions.json     # CloudWatch alarms
│   └── log-insights-queries.txt   # CloudWatch Logs Insights queries
├── scripts/
│   ├── deploy-infrastructure.sh   # Manual infrastructure deployment
│   ├── health-check.sh            # Infrastructure health validation
│   └── validate-infrastructure.sh # Infrastructure validation script
└── README.md                       # Repository documentation
```

### StartTech-Kindson-1148

Application repository with Frontend and Backend code.

```
├── .github/workflows/
│   ├── frontend-ci-cd.yml         # React build and S3 deployment
│   └── backend-ci-cd.yml          # Go API build and EC2 deployment
├── Client/                         # React Frontend
│   ├── src/
│   ├── public/
│   ├── Dockerfile                 # Docker image for testing
│   ├── nginx.conf                 # Nginx configuration for production
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
├── Server/
│   └── MuchToDo/                  # Go Backend
│       ├── cmd/                   # Main application entry point
│       ├── internal/              # Internal packages
│       ├── Dockerfile             # Docker image for production
│       ├── go.mod
│       ├── go.sum
│       └── Makefile
├── scripts/
│   ├── deploy-frontend.sh         # Frontend deployment script
│   ├── deploy-backend.sh          # Backend deployment script
│   ├── health-check.sh            # Application health checks
│   ├── rollback.sh                # Rollback script
│   └── validate-service.sh        # Service validation
├── appspec.yml                    # AWS CodeDeploy configuration
└── README.md
```

## GitHub Actions Workflows

### Infrastructure Repository Workflows

#### 1. terraform-validate.yml

**Trigger:** Push to terraform/ or .github/workflows/terraform-\*.yml paths

**Steps:**

1. Checkout code
2. Configure AWS credentials (OIDC)
3. Setup Terraform
4. Validate Terraform formatting
5. Initialize Terraform backend
6. Validate Terraform syntax
7. Run tflint for linting

**Artifacts:**

- Terraform validation reports
- Linting results

#### 2. terraform-deploy.yml

**Trigger:** Push to main branch, pull requests

**Jobs:**

- **terraform-plan**: Generates and reviews terraform plan
  - Validates configuration
  - Generates deployment plan
  - Comments PR with changes
  - Uploads plan artifacts

- **terraform-apply**: Applies approved terraform plan
  - Requires terraform-plan to pass
  - Only runs on main branch pushes
  - Applies infrastructure changes
  - Exports outputs as artifacts
  - Sends Slack notifications

### Application Repository Workflows

#### 1. frontend-ci-cd.yml

**Trigger:** Push/PR to main/develop branches, changes in Client/

**Jobs:**

**build:**

- Setup Node.js 18
- Install dependencies
- Run ESLint
- Run unit tests
- Security audit (npm audit)
- Build production bundle
- Upload artifacts (dist/)

**deploy:**

- Runs on main branch pushes only
- Configure AWS credentials
- Sync build files to S3
- Invalidate CloudFront cache
- Send Slack notification

**smoke-tests:**

- Wait 30 seconds for deployment
- Check website health
- Retry up to 5 times

#### 2. backend-ci-cd.yml

**Trigger:** Push/PR to main/develop branches, changes in Server/

**Jobs:**

**test:**

- Setup Go 1.25.1
- Download dependencies
- Run unit tests with coverage
- Check coverage (minimum 50%)
- Run integration tests
- Security scan with gosec
- Upload coverage to Codecov

**build:**

- Build Go binary (Linux x86_64)
- Login to ECR
- Build Docker image
- Scan with Trivy for vulnerabilities
- Push to ECR
- Output image URI

**deploy:**

- Runs on main branch pushes only
- Get Auto Scaling Group name
- Update ASG with new image
- Start instance refresh
- Wait 60 seconds
- Smoke tests (health endpoint)
- Send Slack notification

## GitHub Secrets Configuration

### Required Secrets for Infrastructure Repository

```
AWS_ACCOUNT_ID                 # AWS Account ID
TERRAFORM_ROLE_NAME           # IAM role for Terraform
TERRAFORM_STATE_BUCKET        # S3 bucket for Terraform state
TERRAFORM_LOCKS_TABLE         # DynamoDB table for state locks

ENVIRONMENT                   # Deployment environment (dev/staging/prod)

# MongoDB Atlas (if using)
MONGODB_ORG_ID                # MongoDB Organization ID
MONGODB_PUBLIC_KEY            # MongoDB API public key
MONGODB_PRIVATE_KEY           # MongoDB API private key
MONGODB_USERNAME              # MongoDB username
MONGODB_PASSWORD              # MongoDB password

# ECR
ECR_REPOSITORY_URL            # ECR repository URL for Docker images
```

### Required Secrets for Application Repository

```
AWS_ACCESS_KEY_ID             # AWS access key
AWS_SECRET_ACCESS_KEY         # AWS secret key
AWS_REGION                    # AWS region (us-east-1)

# Frontend
S3_BUCKET_NAME                # S3 bucket for frontend hosting
CLOUDFRONT_DISTRIBUTION_ID    # CloudFront distribution ID
VITE_API_URL                  # Backend API URL

# Backend
ECR_REPOSITORY_NAME           # Backend ECR repository name
BACKEND_URL                   # Backend API URL
SLACK_WEBHOOK_URL             # Slack webhook for notifications

# CodeDeploy
CODEDEPLOY_GROUP_PROD         # CodeDeploy group for production
CODEDEPLOY_GROUP_STAGING      # CodeDeploy group for staging
CODEDEPLOY_S3_BUCKET          # S3 bucket for CodeDeploy artifacts
CODEDEPLOY_APP                # CodeDeploy application name

# Optional
SLACK_WEBHOOK_URL             # For deployment notifications
```

## Deployment Process

### Infrastructure Deployment

1. **Automatic (on main branch)**

   ```bash
   git push origin main  # Triggers terraform-deploy.yml
   ```

2. **Manual via GitHub UI**
   - Go to Actions
   - Select "Infrastructure Deployment"
   - Click "Run workflow"
   - Choose action: plan, apply, or destroy

3. **Using Scripts**
   ```bash
   cd terraform
   ./scripts/deploy-infrastructure.sh prod apply
   ```

### Application Deployment

#### Frontend

1. Create PR with changes to Client/
2. Workflow runs tests on PR
3. Merge to main when tests pass
4. Deployment job automatically:
   - Builds React bundle
   - Syncs to S3
   - Invalidates CloudFront
   - Runs smoke tests

#### Backend

1. Create PR with changes to Server/
2. Workflow runs tests on PR
3. Merge to main when tests pass
4. Deployment job automatically:
   - Builds Go binary
   - Creates Docker image
   - Pushes to ECR
   - Triggers EC2 deployment
   - Runs smoke tests

## Monitoring and Observability

### CloudWatch Dashboards

**Access:** AWS CloudWatch Console → Dashboards

**Metrics Monitored:**

- ALB: Response time, request count, HTTP codes
- EC2: CPU utilization, network traffic
- ElastiCache: Memory usage, cache hits/misses
- Application: Errors, latency

### CloudWatch Logs

**Log Groups:**

- `/aws/alb/{environment}/access-logs`
- `/aws/ec2/{environment}/backend`
- `/aws/elasticache/{environment}/redis`
- `/aws/lambda/{environment}/function`

### Log Insights Queries

See `monitoring/log-insights-queries.txt` for pre-built queries:

- Error rate analysis
- Performance bottlenecks
- API latency percentiles
- Database query performance

### CloudWatch Alarms

**Configured Alarms:**

- CPU utilization (high/low)
- Unhealthy targets in ALB
- 5XX error rate
- Redis memory usage
- Database connection errors

## Rollback Procedures

### Frontend Rollback

```bash
# Manual S3 versioning rollback
aws s3api list-object-versions --bucket {bucket-name} \
  --prefix index.html

# Restore previous version
aws s3api copy-object --copy-source {bucket-name}/index.html?versionId={version-id} \
  --bucket {bucket-name} --key index.html

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id {dist-id} --paths "/*"
```

### Backend Rollback

```bash
# Rollback ASG to previous launch template
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name {asg-name} \
  --rollback

# Or update to previous Docker image
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name {asg-name} \
  --desired-capacity 2
```

## Troubleshooting

### Common Issues

**1. Terraform Plan Fails**

- Check AWS credentials in GitHub secrets
- Verify IAM permissions for Terraform role
- Check for syntax errors: `terraform validate`
- Review Terraform debug logs

**2. Frontend Deployment Fails**

- Verify S3 bucket exists and is accessible
- Check CloudFront distribution ID
- Ensure npm dependencies are installed
- Check npm audit for security issues

**3. Backend Deployment Fails**

- Verify ECR repository exists
- Check Docker build logs
- Ensure Go version matches (1.25.1)
- Verify EC2 instances can pull from ECR

**4. Smoke Tests Fail**

- Wait for instances to be ready
- Check security group rules
- Verify health check endpoint exists
- Check ALB target group health

## Best Practices

1. **Always test locally before pushing**
   - Run linters: `eslint .`, `gofmt -l .`
   - Run tests: `npm test`, `go test ./...`
   - Build locally: `npm run build`, `go build`

2. **Use semantic commits**
   - `feat: add new feature`
   - `fix: bug fix`
   - `ci: CI/CD changes`
   - `docs: documentation updates`

3. **Keep secrets secure**
   - Never commit secrets to git
   - Rotate credentials regularly
   - Use AWS Secrets Manager
   - Review IAM policies frequently

4. **Monitor deployments**
   - Check CloudWatch logs
   - Monitor application metrics
   - Review error rates
   - Track deployment history

5. **Plan infrastructure changes**
   - Review terraform plans carefully
   - Test in dev/staging first
   - Keep state files backed up
   - Document infrastructure decisions

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [Docker Documentation](https://docs.docker.com/)
- [Go Programming Language](https://golang.org/)
- [React Documentation](https://react.dev/)
