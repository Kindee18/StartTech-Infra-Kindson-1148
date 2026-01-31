# Terraform Deployment Outputs

**Deployment Date:** January 28, 2026  
**Environment:** dev  
**AWS Account:** 125168806853  
**Region:** us-east-1

---

## 🌐 Application URLs

### Frontend

- **CloudFront URL:** https://dcv1uj0eg0tp4.cloudfront.net
- **S3 Bucket:** dev-starttech-frontend-125168806853
- **Distribution ID:** E7HH43N1VPIVH

### Backend API

- **ALB DNS:** http://dev-alb-284302811.us-east-1.elb.amazonaws.com
- **Health Check:** http://dev-alb-284302811.us-east-1.elb.amazonaws.com/health

---

## 🐳 Container Registry

**ECR Repository URL:**

```
125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend
```

**Docker Login Command:**

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 125168806853.dkr.ecr.us-east-1.amazonaws.com
```

**Build & Push Example:**

```bash
cd Server/MuchToDo
docker build -t dev-starttech-backend .
docker tag dev-starttech-backend:latest 125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend:latest
docker push 125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend:latest
```

---

## 🔐 GitHub Secrets Configuration

### For Repository: Kindee18/StartTech-Kindson-1148

Go to: https://github.com/Kindee18/StartTech-Kindson-1148/settings/secrets/actions

Add the following secrets:

#### AWS Configuration

```
AWS_REGION
us-east-1
```

#### GitHub OIDC Roles

```
AWS_BACKEND_ROLE_ARN
arn:aws:iam::125168806853:role/dev-github-backend-role
```

```
AWS_FRONTEND_ROLE_ARN
arn:aws:iam::125168806853:role/dev-github-frontend-role
```

#### Frontend Deployment

```
S3_BUCKET
dev-starttech-frontend-125168806853
```

```
CLOUDFRONT_DISTRIBUTION_ID
E7HH43N1VPIVH
```

```
API_BASE_URL
http://dev-alb-284302811.us-east-1.elb.amazonaws.com
```

#### Backend Deployment

```
ECR_REPOSITORY
125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend
```

```
ALB_DNS_NAME
dev-alb-284302811.us-east-1.elb.amazonaws.com
```

#### Database & Cache

```
REDIS_URL
redis://dev-redis.luzj76.0001.use1.cache.amazonaws.com:6379
```

```
MONGODB_URI
mongodb://placeholder-set-mongodb-atlas-later
```

---

## 📊 Monitoring & Logs

### CloudWatch Dashboard

https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=dev-starttech-dashboard

### Log Groups

- **Backend Logs:** `/aws/ec2/dev/backend`
- **ALB Logs:** `/aws/alb/dev`
- **Redis Engine Log:** `/aws/elasticache/dev/redis/engine-log`
- **Redis Slow Log:** `/aws/elasticache/dev/redis/slow-log`

### SNS Alarms Topic

```
arn:aws:sns:us-east-1:125168806853:dev-starttech-alarms
```

**Subscribe to Alerts:**

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:125168806853:dev-starttech-alarms \
  --protocol email \
  --notification-endpoint your-email@example.com
```

---

## 🏗️ Infrastructure Details

### Networking

- **VPC ID:** vpc-0bf539e24e703bebe
- **CIDR:** 10.0.0.0/16
- **Availability Zones:** us-east-1a, us-east-1b
- **Public Subnets:** 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets:** 10.0.10.0/24, 10.0.11.0/24

### Compute

- **Auto Scaling Group:** dev-backend-asg
- **Min Size:** 2
- **Max Size:** 6
- **Desired:** 2
- **Instance Type:** t3.medium
- **IAM Role:** dev-ec2-role

### Load Balancer

- **Name:** dev-alb
- **ARN:** arn:aws:elasticloadbalancing:us-east-1:125168806853:loadbalancer/app/dev-alb/05ee077252877e98
- **DNS:** dev-alb-284302811.us-east-1.elb.amazonaws.com
- **Target Group:** dev-backend-tg

### Cache

- **ElastiCache Cluster:** dev-redis
- **Node Type:** cache.t3.micro
- **Endpoint:** dev-redis.luzj76.0001.use1.cache.amazonaws.com:6379
- **Port:** 6379

### State Management

- **S3 Bucket:** dev-starttech-terraform-state-125168806853
- **DynamoDB Table:** dev-starttech-terraform-locks

---

## 🚀 Quick Deployment Commands

### Deploy Backend

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 125168806853.dkr.ecr.us-east-1.amazonaws.com

# Build and push
cd /home/kindson/StartTech-Kindson-1148/Server/MuchToDo
docker build -t dev-starttech-backend .
docker tag dev-starttech-backend:latest 125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend:latest
docker push 125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend:latest

# Update terraform with actual image
cd /home/kindson/StartTech-Infra-Kindson-1148/terraform
# Edit terraform.tfvars: docker_image = "125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend:latest"
terraform apply -var="use_mongodb_atlas=false"
```

### Deploy Frontend

```bash
cd /home/kindson/StartTech-Kindson-1148/Client

# Build with correct API URL
VITE_API_BASE_URL=http://dev-alb-284302811.us-east-1.elb.amazonaws.com npm run build

# Upload to S3
aws s3 sync dist/ s3://dev-starttech-frontend-125168806853/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id E7HH43N1VPIVH --paths "/*"
```

---

## 🧪 Health Check Commands

### Backend Health

```bash
curl http://dev-alb-284302811.us-east-1.elb.amazonaws.com/health
```

### Redis Connection

```bash
redis-cli -h dev-redis.luzj76.0001.use1.cache.amazonaws.com -p 6379 ping
```

### Check ASG Instances

```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names dev-backend-asg --query 'AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus,LifecycleState]' --output table
```

### Check ECR Images

```bash
aws ecr describe-images --repository-name dev-starttech-backend --query 'imageDetails[*].[imageTags[0],imagePushedAt]' --output table
```

---

## 💰 Cost Estimation

**Monthly Cost Breakdown (Approximate):**

- ALB: ~$16-20
- NAT Gateways (2): ~$65-70
- EC2 Instances (2x t3.medium): ~$60-70
- ElastiCache (cache.t3.micro): ~$12-15
- CloudFront: ~$1-10 (usage-based)
- S3 Storage: ~$1-5
- CloudWatch Logs: ~$5-10
- ECR: ~$1-5

**Total Estimated: $150-170/month**

---

## 📝 Next Steps

1. ✅ **Infrastructure deployed**
2. ⏳ **Configure GitHub Secrets** (see above)
3. ⏳ **Build & Push Docker Image**
4. ⏳ **Update terraform.tfvars with actual docker_image**
5. ⏳ **Run terraform apply again**
6. ⏳ **Deploy frontend to S3**
7. ⏳ **Test application**
8. ⏳ **Subscribe to SNS alarms**
9. ⏳ **Set up MongoDB Atlas** (optional)
10. ⏳ **Configure custom domain & HTTPS** (optional)

---

## 🔄 Update Infrastructure

When you need to make changes:

```bash
cd /home/kindson/StartTech-Infra-Kindson-1148/terraform

# Edit your .tf files or terraform.tfvars

# Plan changes
terraform plan -var="use_mongodb_atlas=false" -out=updated.tfplan

# Apply changes
terraform apply updated.tfplan
```

---

## 🗑️ Teardown (When Needed)

⚠️ **WARNING:** This will destroy ALL resources

```bash
cd /home/kindson/StartTech-Infra-Kindson-1148/terraform
terraform destroy -var="use_mongodb_atlas=false"
```

---

**Generated:** January 28, 2026  
**Terraform Version:** 1.14.3  
**AWS Provider:** ~> 5.0
