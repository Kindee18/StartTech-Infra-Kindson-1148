# StartTech Infrastructure Architecture

## System Overview

This document provides a detailed overview of the StartTech infrastructure architecture, design decisions, and component interactions.

## High-Level Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Internet Traffic                         │
└────────────────────┬───────────────────────────────────────┘
                     │
          ┌──────────▼──────────┐
          │   CloudFront CDN    │
          │  (Cache & Delivery) │
          └──────────┬──────────┘
                     │
       ┌─────────────┴──────────────┐
       │                            │
   ┌───▼────┐              ┌────────▼────────┐
   │   S3   │              │ ALB (Port 80/443)
   │Frontend│              └────────┬────────┘
   └────────┘                       │
                    ┌──────────────┘
                    │
         ┌──────────▼───────────┐
         │ EC2 Auto Scaling     │
         │ Group (2-6 instances)│
         └──────────┬───────────┘
                    │
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
┌─────────┐    ┌──────────┐   ┌──────────────┐
│  Redis  │    │ MongoDB  │   │  CloudWatch  │
│Elastic  │    │   Atlas  │   │  Logs/Alarms │
│Cache    │    │          │   │              │
└─────────┘    └──────────┘   └──────────────┘
```

## Network Architecture

### VPC Design

- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (2 AZs)
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24 (2 AZs)

### Traffic Flow

1. **Inbound (Public)**
   - Internet → ALB (port 80/443) → EC2 instances
   - Requests validated by security groups

2. **Internal (Private)**
   - EC2 → RDS/MongoDB (port 27017)
   - EC2 → ElastiCache Redis (port 6379)
   - NAT Gateway for outbound traffic

3. **Outbound**
   - EC2 → NAT Gateway → Internet
   - ECR image pulls via NAT Gateway

### Security Groups

| Name     | Direction | Port   | Source/Destination | Purpose            |
| -------- | --------- | ------ | ------------------ | ------------------ |
| ALB-SG   | Inbound   | 80/443 | 0.0.0.0/0          | HTTP/HTTPS traffic |
| EC2-SG   | Inbound   | 8080   | ALB-SG             | App traffic        |
| EC2-SG   | Inbound   | 22     | SSH CIDR           | SSH access         |
| RDS-SG   | Inbound   | 27017  | EC2-SG             | MongoDB            |
| Redis-SG | Inbound   | 6379   | EC2-SG             | Redis              |

## Compute Architecture

### Application Load Balancer

**Configuration**:

- Type: Application Load Balancer
- Subnets: 2 public subnets (multi-AZ)
- Target Type: Instances
- Port: 80 (HTTP), 443 (HTTPS ready)

**Target Group**:

- Name: `dev-backend-tg`
- Port: 8080
- Health Check:
  - Path: `/health`
  - Interval: 30s
  - Timeout: 3s
  - Healthy threshold: 2
  - Unhealthy threshold: 2

**Routing Rules**:

- All HTTP traffic → target group
- HTTPS redirect ready (add listener for 443)

### Auto Scaling Group

**Configuration**:

- Min Size: 2 instances
- Max Size: 6 instances
- Desired: 2 instances
- Subnets: Private subnets only
- Health Check: ELB health check

**Launch Template**:

- AMI: Latest Amazon Linux 2
- Instance Type: t3.medium (configurable)
- IAM Role: EC2CloudWatchRole
- Storage: 20GB gp3 root volume

**User Data**:

- Installs Docker
- Pulls Docker image from ECR
- Starts container with:
  - Port mapping: 8080:8080
  - CloudWatch logging
  - Environment variables injected

### Auto Scaling Policies

| Policy     | Metric | Threshold | Action      |
| ---------- | ------ | --------- | ----------- |
| Scale Up   | CPU    | > 70%     | +1 instance |
| Scale Down | CPU    | < 30%     | -1 instance |

**Cooldown**: 300 seconds to prevent flapping

## Storage Architecture

### S3 Frontend Bucket

**Purpose**: Static React application hosting

**Configuration**:

- Versioning: Enabled
- Encryption: AES256 (server-side)
- Public Access: Blocked
- Access: CloudFront OAI only

**Lifecycle**:

```
Current versions → keep indefinitely
Previous versions → delete after 30 days
```

### CloudFront Distribution

**Purpose**: CDN for frontend with global caching

**Configuration**:

- Origin: S3 bucket (via OAI)
- HTTPS: Default certificate (can upgrade to ACM)
- Cache Behaviors:
  - `/assets/*`: 1 year TTL (immutable)
  - `/`: Default 1 hour TTL
  - `index.html`: 0 TTL for SPA routing

**Error Handling**:

- 404 → index.html (SPA routing)
- 403 → index.html (SPA routing)

### Terraform State Storage

**Backend**:

- S3 bucket (remote state)
- Encryption: SSE-S3
- Versioning: Enabled
- DynamoDB table for state locking

**Access**:

- GitHub Actions: IAM role via OIDC
- Local: AWS credentials

## Database Architecture

### MongoDB Atlas (Primary)

**Deployment**:

- Tier: M5 (2GB)
- Replication: 3-node replica set
- Backup: Continuous with 35-day retention
- Multi-region: Available (not default)

**Networking**:

- IP Allowlist: EC2 security group
- Data encryption: Enabled
- Transport encryption: TLS

**Databases**:

- `starttech`: Production database
- `starttech_staging`: Staging database

**Users**:

- `starttech_app`: Full read/write access

### Alternative: Self-Hosted MongoDB

If using EC2-hosted MongoDB:

**Installation**:

- EC2 instance in private subnet
- Same security group as app
- Automated backups to S3

**Connection String**:

```
mongodb://user:password@mongodb.internal:27017/starttech
```

## Caching Architecture

### ElastiCache Redis

**Configuration**:

- Engine: Redis 7.0
- Node Type: cache.t3.micro (developable)
- Num Nodes: 1 (single-AZ) or 2+ (multi-AZ)
- Port: 6379

**Encryption**:

- At-rest: Enabled
- Transit: Optional (auth token if enabled)

**Backups**:

- Snapshots: Enabled (5-day retention)
- Automatic failover: Enabled (multi-AZ only)

**Monitoring**:

- Slow log: CloudWatch logs
- Engine log: CloudWatch logs
- Metrics: CPUUtilization, NetworkBytesIn, Evictions

**Use Cases**:

- Session storage
- Cache layer for frequently accessed data
- Real-time notifications

## Monitoring & Logging Architecture

### Log Groups

```
/aws/ec2/dev/backend           → Application logs
/aws/alb/dev                   → ALB access logs
/aws/elasticache/dev/redis/slow-log   → Slow operations
/aws/elasticache/dev/redis/engine-log → Redis internals
```

### Metrics & Alarms

**System Metrics**:

- ALB: Request count, response time, error rates
- EC2: CPU, network throughput
- RDS: Connections, read/write latency
- ElastiCache: CPU, memory, evictions

**Alarms**:

- ALB unhealthy targets → SNS
- CPU high (>70%) → Scale up
- CPU low (<30%) → Scale down
- Response time high (>1s) → SNS
- Redis memory (>90%) → SNS
- Redis evictions → SNS

### Dashboard

CloudWatch dashboard with:

- ALB metrics (requests, errors, response time)
- EC2 metrics (CPU, network)
- Redis metrics (memory, CPU, evictions)
- Error rates from logs

## IAM & Security Architecture

### GitHub OIDC Provider

**Purpose**: Secure CI/CD authentication without secrets

**Setup**:

- OIDC Provider URL: https://token.actions.githubusercontent.com
- Audience: sts.amazonaws.com
- Thumbprint: Verified against GitHub

**Trust Relationships**:

```
Frontend CI/CD:
  Repo: Kindee18/StartTech-Kindson-1148
  Branch: main
  Role: dev-github-frontend-role

Backend CI/CD:
  Repo: Kindee18/StartTech-Kindson-1148
  Branch: main
  Role: dev-github-backend-role

Infrastructure:
  Repo: Kindee18/StartTech-Infra-Kindson-1148
  Branch: main
  Role: dev-github-infra-role
```

### IAM Roles

| Role                 | Permissions              | Used By              |
| -------------------- | ------------------------ | -------------------- |
| EC2CloudWatchRole    | CloudWatch logs, metrics | EC2 instances        |
| github-frontend-role | S3, CloudFront           | Frontend CI/CD       |
| github-backend-role  | ECR, CodeDeploy          | Backend CI/CD        |
| github-infra-role    | All infrastructure       | Infrastructure CI/CD |

## Data Flow

### Application Request

```
1. DNS → CloudFront
2. CloudFront → S3 (if frontend)
3. CloudFront → ALB (if API)
4. ALB health check → EC2
5. EC2 app → MongoDB (async)
6. EC2 app → Redis (cache)
7. Response → ALB → CloudFront → Client
```

### Deployment Flow

```
GitHub Push (main)
    ↓
GitHub Actions Workflow
    ↓
Terraform Validate & Plan
    ↓
Terraform Apply
    ↓
New EC2 instances launch with new Docker image
    ↓
Health checks verify
    ↓
Load Balancer routes to new instances
```

### Logging Flow

```
Application → CloudWatch Logs
              ↓
          Log Insights (queries)
              ↓
              Dashboards
              ↓
              Alarms
              ↓
              SNS Topic
              ↓
              Email/Slack Notification
```

## High Availability & Disaster Recovery

### High Availability

1. **Multi-AZ Deployment**:
   - 2 public subnets (different AZs)
   - 2 private subnets (different AZs)
   - NAT Gateway in each AZ
   - Auto Scaling spans both AZs

2. **Load Balancing**:
   - ALB distributes traffic
   - Health checks remove unhealthy targets
   - Auto Scaling replaces failed instances

3. **Database**:
   - MongoDB Atlas 3-node replica set
   - Automatic failover
   - Multi-region optional

4. **Cache**:
   - ElastiCache with multi-AZ (if enabled)
   - Automatic failover
   - Snapshots for recovery

### Disaster Recovery

1. **Backup Strategy**:
   - MongoDB: Continuous backup (35-day retention)
   - Redis: Daily snapshots (5-day retention)
   - Terraform state: Versioned in S3
   - Application: Docker image tags immutable

2. **Recovery Procedures**:
   - Infrastructure: `terraform apply`
   - Data: MongoDB restore from backup
   - Application: Redeploy from ECR
   - See RUNBOOK.md for details

3. **RTO/RPO**:
   - RTO (Recovery Time Objective): < 15 minutes
   - RPO (Recovery Point Objective): < 1 hour

## Performance Considerations

### Caching Strategy

1. **CloudFront**:
   - Static assets: 1 year TTL
   - HTML: No cache (always fresh)
   - API: Conditional caching

2. **Redis**:
   - Session storage (1 hour TTL)
   - Frequently accessed data
   - Real-time notifications

3. **Database**:
   - Indexes on common queries
   - Connection pooling
   - Read replicas (if needed)

### Scaling Strategy

1. **Horizontal**:
   - Auto Scaling for EC2
   - ElastiCache cluster mode
   - MongoDB sharding (future)

2. **Vertical**:
   - Larger instance types
   - Larger Redis node type
   - MongoDB M10+

## Cost Optimization

### Current Architecture Cost

Monthly estimate (US East 1):

- ALB: $18
- EC2 (2x t3.medium): $56
- ElastiCache: $16
- MongoDB Atlas: $57
- S3 + CloudFront: $15
- CloudWatch: $10
- **Total: ~$172**

### Optimization Opportunities

1. **Reserved Instances**: 30-50% savings
2. **Spot Instances**: 70% savings (for non-critical)
3. **Smaller Instances**: Scale per demand
4. **Scheduled Scaling**: Different capacities per time
5. **Data Transfer**: Optimize with CloudFront

## Security Considerations

### Network Security

- VPC isolates infrastructure
- Security groups restrict access
- NACLs provide additional layer
- VPC Flow Logs for monitoring

### Data Security

- Encryption at rest (S3, RDS, ElastiCache)
- Encryption in transit (TLS)
- IAM for access control
- Secrets in AWS Secrets Manager

### Application Security

- Health checks verify application health
- CloudWatch alarms on errors
- Security scanning in CI/CD
- Regular updates via Terraform

## Monitoring Strategy

### Key Metrics

1. **Availability**: Uptime % (target: 99.9%)
2. **Performance**: Response time (target: <500ms)
3. **Reliability**: Error rate (target: <0.1%)
4. **Scalability**: Can scale to 2x load

### SLOs

- Availability: 99.9% (43 minutes downtime/month)
- Response time: 95th percentile < 1 second
- Error rate: <0.1% of requests

## Future Enhancements

1. **HTTPS**: Add ACM certificate
2. **WAF**: Add AWS WAF to ALB
3. **DDoS**: Enable AWS Shield
4. **Monitoring**: Add X-Ray tracing
5. **Multi-Region**: Global deployment
6. **Kubernetes**: Migrate to EKS
7. **Serverless**: Functions for specific tasks
8. **Database**: RDS Aurora for SQL needs
