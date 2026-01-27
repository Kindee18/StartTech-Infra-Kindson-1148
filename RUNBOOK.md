# StartTech Infrastructure Operations Runbook

Operational procedures and troubleshooting guide for StartTech infrastructure.

## Quick Reference

### Deployment

```bash
./scripts/validate-infrastructure.sh       # Validate config
./scripts/deploy-infrastructure.sh dev plan   # Review changes
./scripts/deploy-infrastructure.sh dev apply  # Deploy
./scripts/health-check.sh dev              # Verify
```

### Monitoring

```bash
# CloudWatch Logs
aws logs tail /aws/ec2/dev/backend --follow

# Check ALB
aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, 'dev-alb')]"

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names dev-backend-asg

# Check Redis
aws elasticache describe-cache-clusters --cache-cluster-id dev-redis --show-cache-node-info
```

## Standard Operating Procedures

### 1. Initial Deployment

**Prerequisites**:

- [ ] AWS account created
- [ ] Terraform installed
- [ ] AWS CLI configured
- [ ] S3 bucket created for state
- [ ] DynamoDB table created for locks
- [ ] GitHub OIDC provider configured
- [ ] terraform.tfvars updated

**Steps**:

```bash
# 1. Clone repository
git clone https://github.com/Kindee18/StartTech-Infra-Kindson-1148.git
cd StartTech-Infra-Kindson-1148

# 2. Create terraform.tfvars from example
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# 3. Edit with your values
nano terraform/terraform.tfvars

# 4. Initialize Terraform
cd terraform
terraform init \
  -backend-config="bucket=YOUR_BUCKET" \
  -backend-config="key=starttech/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=YOUR_TABLE"

# 5. Validate
terraform validate

# 6. Plan
terraform plan -out=tfplan

# 7. Review plan output carefully

# 8. Apply
terraform apply tfplan

# 9. Check outputs
terraform output -json > outputs.json

# 10. Verify deployment
cd ..
./scripts/health-check.sh dev
```

**Expected Output**:

- All ALB targets healthy
- EC2 instances running
- Redis endpoint active
- MongoDB connection verified
- CloudWatch logs populated

### 2. Updating Configuration

**When to update**:

- Instance type changes
- Scaling parameters
- Database configuration
- Cache settings

**Steps**:

```bash
# 1. Edit terraform.tfvars
nano terraform/terraform.tfvars

# 2. Plan changes
cd terraform
terraform plan -out=tfplan

# 3. Review differences
terraform show tfplan

# 4. Apply if correct
terraform apply tfplan
```

### 3. Adding New Resources

**Example: Adding EC2 Security Rule**:

```hcl
# In modules/networking/main.tf
resource "aws_security_group_rule" "new_rule" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.ec2.id
}
```

```bash
# Plan and apply
terraform plan
terraform apply
```

### 4. Scaling Infrastructure

#### Manual Scaling

```bash
# Increase desired capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-backend-asg \
  --desired-capacity 3

# Check status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-backend-asg \
  --query "AutoScalingGroups[0].[Instances,DesiredCapacity,MinSize,MaxSize]"
```

#### Update via Terraform

```hcl
# In terraform.tfvars
desired_capacity = 3  # Was 2

# Apply changes
terraform apply
```

### 5. Database Operations

#### MongoDB Atlas

```bash
# List clusters
aws mongodb-atlas clusters list

# Backup status
aws mongodb-atlas backup describe \
  --project-id YOUR_PROJECT_ID \
  --cluster-id YOUR_CLUSTER_ID

# Restore from backup
aws mongodb-atlas backup restore \
  --project-id YOUR_PROJECT_ID \
  --backup-id YOUR_BACKUP_ID \
  --target-cluster-name restored-cluster
```

#### Connection String

```bash
# Get from Terraform output
terraform output mongodb_connection_string

# Or retrieve from MongoDB Atlas console
# Connection → Connect Your Application
```

### 6. Cache Management

#### Redis Operations

```bash
# Get endpoint
aws elasticache describe-cache-clusters \
  --cache-cluster-id dev-redis \
  --query "CacheClusters[0].CacheNodes[0].Endpoint"

# Connect and test
redis-cli -h <endpoint> -p 6379 ping

# Clear cache (if needed)
redis-cli -h <endpoint> -p 6379 FLUSHALL

# Monitor
redis-cli -h <endpoint> -p 6379 MONITOR
```

#### Redis Snapshots

```bash
# Create snapshot
aws elasticache create-snapshot \
  --cache-cluster-id dev-redis \
  --snapshot-name dev-redis-$(date +%s)

# List snapshots
aws elasticache describe-snapshots \
  --cache-cluster-id dev-redis

# Restore from snapshot
aws elasticache restore-cache-cluster-from-snapshot \
  --cache-cluster-id dev-redis-restored \
  --snapshot-name YOUR_SNAPSHOT_NAME
```

### 7. Log Analysis

#### Application Errors

```bash
# Get recent errors
aws logs filter-log-events \
  --log-group-name /aws/ec2/dev/backend \
  --filter-pattern "ERROR" \
  --start-time $(($(date +%s) - 3600))000

# With more detail
aws logs filter-log-events \
  --log-group-name /aws/ec2/dev/backend \
  --filter-pattern "[ERROR]" \
  --query "events[*].[timestamp,message]" \
  --output table
```

#### Performance Analysis

```bash
# Slow requests (>1000ms)
aws logs filter-log-events \
  --log-group-name /aws/ec2/dev/backend \
  --filter-pattern "[duration > 1000]" \
  --query "events[*].message"
```

### 8. Monitoring & Alarms

#### Check Alarm Status

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix dev-backend \
  --query "MetricAlarms[*].[AlarmName,StateValue]" \
  --output table

# Check specific alarm
aws cloudwatch describe-alarms \
  --alarm-names dev-backend-cpu-high
```

#### Manual Metric Check

```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Response Time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## Troubleshooting

### Issue: Instances Not Starting

**Symptoms**: EC2 instances in terminating or stopped state

**Diagnosis**:

```bash
# Check Auto Scaling activity
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name dev-backend-asg \
  --max-records 10 \
  --query "Activities[*].[StartTime,Description,Cause]"

# Check CloudWatch logs for errors
aws logs tail /aws/ec2/dev/backend --follow
```

**Solutions**:

1. Check user data errors

   ```bash
   # SSH into instance
   ssh -i key.pem ec2-user@instance-ip
   tail -100 /var/log/cloud-init-output.log
   ```

2. Verify Docker image exists in ECR

   ```bash
   aws ecr describe-images \
     --repository-name dev-starttech-backend
   ```

3. Check IAM role permissions
   ```bash
   aws iam get-role-policy \
     --role-name dev-ec2-role \
     --policy-name dev-ec2-ecr-policy
   ```

### Issue: ALB Health Check Failures

**Symptoms**: All targets showing as unhealthy

**Diagnosis**:

```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/dev-backend-tg/abc123

# Test endpoint manually
curl http://instance-private-ip:8080/health
```

**Solutions**:

1. Check application is running

   ```bash
   ssh -i key.pem ec2-user@instance-ip
   docker ps
   curl localhost:8080/health
   ```

2. Verify security group allows 8080 from ALB

   ```bash
   # Check security group rules
   aws ec2 describe-security-groups \
     --group-ids sg-12345678 \
     --query "SecurityGroups[0].IpPermissions"
   ```

3. Check application logs
   ```bash
   ssh -i key.pem ec2-user@instance-ip
   docker logs starttech-backend
   ```

### Issue: High CPU Usage

**Symptoms**: CPU > 70%, instances scaling up repeatedly

**Diagnosis**:

```bash
# Get CPU metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Check processes on instance
ssh -i key.pem ec2-user@instance-ip
top -n 1
```

**Solutions**:

1. Increase instance type

   ```hcl
   # In terraform.tfvars
   instance_type = "t3.large"  # Was t3.medium
   terraform apply
   ```

2. Increase scaling thresholds

   ```bash
   # Check current policy
   aws autoscaling describe-scaling-policies \
     --auto-scaling-group-name dev-backend-asg

   # Update policy threshold
   aws autoscaling put-scaling-policy \
     --auto-scaling-group-name dev-backend-asg \
     --policy-name dev-scale-up \
     --scaling-adjustment 2 \
     --adjustment-type ChangeInCapacity
   ```

3. Optimize application code
   - Check for memory leaks
   - Profile CPU usage
   - Optimize database queries

### Issue: Database Connection Errors

**Symptoms**: Connection timeouts, "cannot connect to MongoDB"

**Diagnosis**:

```bash
# Test connectivity from EC2
ssh -i key.pem ec2-user@instance-ip
mongosh "mongodb+srv://user:password@cluster.mongodb.net/database"

# Check MongoDB Atlas whitelist
# AWS Console → MongoDB Atlas → Network Access
```

**Solutions**:

1. Whitelist EC2 security group
   - MongoDB Atlas console → Network Access
   - Add EC2 security group IP/CIDR

2. Check connection string

   ```bash
   # Get from Terraform output
   terraform output mongodb_connection_string
   ```

3. Verify credentials in application
   ```bash
   # Check environment variables
   ssh -i key.pem ec2-user@instance-ip
   docker logs starttech-backend | grep -i mongodb
   ```

### Issue: Redis Connection Errors

**Symptoms**: Cache not working, "connection refused"

**Diagnosis**:

```bash
# Check cluster status
aws elasticache describe-cache-clusters \
  --cache-cluster-id dev-redis \
  --show-cache-node-info

# Test from EC2
ssh -i key.pem ec2-user@instance-ip
redis-cli -h redis-endpoint.cache.amazonaws.com -p 6379 ping
```

**Solutions**:

1. Verify security group allows port 6379

   ```bash
   aws ec2 describe-security-groups \
     --group-ids sg-redis \
     --query "SecurityGroups[0].IpPermissions"
   ```

2. Check cluster is available

   ```bash
   aws elasticache describe-cache-clusters \
     --query "CacheClusters[?CacheClusterId=='dev-redis'].CacheClusterStatus"
   ```

3. Verify credentials if auth enabled
   ```bash
   redis-cli -h endpoint -p 6379 -a YOUR_AUTH_TOKEN ping
   ```

### Issue: Terraform State Locked

**Symptoms**: "Error acquiring the state lock" when running terraform

**Diagnosis**:

```bash
# Check DynamoDB lock table
aws dynamodb scan \
  --table-name dev-starttech-terraform-locks
```

**Solution**:

```bash
# If lock is stuck (verify it's not in use first!)
aws dynamodb delete-item \
  --table-name dev-starttech-terraform-locks \
  --key '{"LockID":{"S":"starttech/terraform.tfstate"}}'

# Retry terraform command
terraform apply
```

### Issue: Deployment Takes Too Long

**Symptoms**: Terraform apply stuck or takes > 10 minutes

**Diagnosis**:

```bash
# Check for errors
export TF_LOG=INFO
terraform apply

# Check resource status
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,LaunchTime]"
```

**Solutions**:

1. Check instance boot issues
   - Look at CloudWatch logs
   - Check CloudInit output

2. Increase timeout

   ```bash
   export AWS_MAX_ATTEMPTS=30
   export AWS_POLL_DELAY_SECONDS=10
   ```

3. Apply in stages

   ```bash
   # Apply networking first
   terraform apply -target=module.networking

   # Then compute
   terraform apply -target=module.compute
   ```

## Disaster Recovery Procedures

### Full Cluster Failure Recovery

**Time: ~15 minutes**

```bash
# 1. Assess situation
./scripts/health-check.sh dev

# 2. Check backups available
aws backup list-recovery-points-by-resource \
  --by-resource-type MongoDB

# 3. Redeploy infrastructure
terraform apply

# 4. Restore database from backup
# MongoDB Atlas: Restore from snapshot in console

# 5. Restore Redis
aws elasticache restore-cache-cluster-from-snapshot \
  --cache-cluster-id dev-redis-restored \
  --snapshot-name latest-snapshot

# 6. Verify all services
./scripts/health-check.sh dev
```

### Database Corruption Recovery

**Steps**:

```bash
# 1. Stop application (drain connections)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-backend-asg \
  --desired-capacity 0

# 2. Identify good backup
aws mongodb-atlas backup describe \
  --project-id YOUR_PROJECT

# 3. Restore to new cluster
# Use MongoDB Atlas console: Backup & Restore

# 4. Verify data
mongosh "mongodb+srv://user:pass@new-cluster.mongodb.net/db"

# 5. Update connection string in Terraform
# Edit terraform.tfvars with new host

# 6. Redeploy application
terraform apply

# 7. Scale up
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-backend-asg \
  --desired-capacity 2
```

## Maintenance Windows

### Recommended Schedule

- **Backup Verification**: Weekly Monday 2 AM UTC
- **Security Patches**: Monthly second Tuesday
- **Capacity Planning**: Monthly first Friday
- **Disaster Recovery Drill**: Quarterly

### Maintenance Steps

```bash
# Before maintenance
# 1. Notify team
# 2. Create snapshot
# 3. Drain connections

# During maintenance
# Execute necessary changes

# After maintenance
# 1. Health checks
# 2. Performance verification
# 3. Notify team of completion
```

## Contacts & Escalation

| Issue           | Contact       | Response Time |
| --------------- | ------------- | ------------- |
| Infrastructure  | DevOps team   | 15 min        |
| Database        | Database team | 30 min        |
| Application     | App team      | 15 min        |
| Critical outage | On-call       | 5 min         |

## Useful Commands Reference

```bash
# Infrastructure
aws autoscaling describe-auto-scaling-groups
aws elbv2 describe-load-balancers
aws elasticache describe-cache-clusters
aws logs tail /aws/ec2/dev/backend --follow

# Terraform
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
terraform state list
terraform state show module.compute

# Monitoring
aws cloudwatch describe-alarms
aws cloudwatch get-metric-statistics
aws logs filter-log-events
aws logs start-query

# Deployment
./scripts/validate-infrastructure.sh
./scripts/deploy-infrastructure.sh dev plan
./scripts/deploy-infrastructure.sh dev apply
./scripts/health-check.sh dev
```

## Emergency Contacts

- AWS Support: https://console.aws.amazon.com/support
- GitHub Status: https://www.githubstatus.com/
- MongoDB Status: https://status.mongodb.com/

---

**Document Version**: 1.0
**Last Updated**: January 2026
**Maintained By**: DevOps Team
