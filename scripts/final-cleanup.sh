#!/bin/bash

set -e

# Final cleanup of all orphaned AWS resources
# Run this before attempting fresh terraform deployment

AWS_REGION="us-east-1"
ACCOUNT_ID="125168806853"
ENV="dev"

echo "======================================"
echo "Final AWS Resource Cleanup"
echo "======================================"
echo ""
echo "This will delete ALL orphaned resources in order:"
echo "1. CloudWatch Log Groups"
echo "2. ElastiCache resources"
echo "3. ECR repositories"
echo "4. IAM roles and instance profiles"
echo "5. S3 buckets (after emptying)"
echo "6. DynamoDB tables"
echo "7. OIDC provider"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# 1. Delete CloudWatch Log Groups
echo ""
echo "==> Deleting CloudWatch Log Groups..."
for log_group in "/aws/ec2/${ENV}/backend" "/aws/alb/${ENV}" "/aws/elasticache/${ENV}/redis/engine-log" "/aws/elasticache/${ENV}/redis/slow-log"; do
    if aws logs describe-log-groups --log-group-name-prefix "$log_group" --region $AWS_REGION 2>/dev/null | grep -q "logGroups"; then
        echo "  Deleting: $log_group"
        aws logs delete-log-group --log-group-name "$log_group" --region $AWS_REGION 2>/dev/null || echo "  Already deleted or doesn't exist"
    else
        echo "  Not found: $log_group"
    fi
done

# 2. Delete ElastiCache resources
echo ""
echo "==> Deleting ElastiCache Parameter Groups..."
for param_group in "${ENV}-redis-params"; do
    if aws elasticache describe-cache-parameter-groups --cache-parameter-group-name "$param_group" --region $AWS_REGION 2>/dev/null | grep -q "CacheParameterGroups"; then
        echo "  Deleting: $param_group"
        aws elasticache delete-cache-parameter-group --cache-parameter-group-name "$param_group" --region $AWS_REGION 2>/dev/null || echo "  Failed to delete"
    else
        echo "  Not found: $param_group"
    fi
done

echo ""
echo "==> Deleting ElastiCache Subnet Groups..."
for subnet_group in "${ENV}-elasticache-subnet-group"; do
    if aws elasticache describe-cache-subnet-groups --cache-subnet-group-name "$subnet_group" --region $AWS_REGION 2>/dev/null | grep -q "CacheSubnetGroups"; then
        echo "  Deleting: $subnet_group"
        aws elasticache delete-cache-subnet-group --cache-subnet-group-name "$subnet_group" --region $AWS_REGION 2>/dev/null || echo "  Failed to delete"
    else
        echo "  Not found: $subnet_group"
    fi
done

# 3. Delete ECR repositories
echo ""
echo "==> Deleting ECR Repositories..."
for repo in "${ENV}-starttech-backend" "${ENV}-starttech-frontend"; do
    if aws ecr describe-repositories --repository-names "$repo" --region $AWS_REGION 2>/dev/null | grep -q "repositories"; then
        echo "  Deleting: $repo (force, including all images)"
        aws ecr delete-repository --repository-name "$repo" --region $AWS_REGION --force 2>/dev/null || echo "  Failed to delete"
    else
        echo "  Not found: $repo"
    fi
done

# 4. Delete IAM roles (remove instance profiles and policies first)
echo ""
echo "==> Deleting IAM Roles..."
for role in "${ENV}-ec2-role"; do
    if aws iam get-role --role-name "$role" 2>/dev/null | grep -q "Role"; then
        echo "  Processing role: $role"
        
        # Remove from instance profiles
        echo "    Checking instance profiles..."
        instance_profiles=$(aws iam list-instance-profiles-for-role --role-name "$role" --query 'InstanceProfiles[].InstanceProfileName' --output text 2>/dev/null || echo "")
        if [ ! -z "$instance_profiles" ]; then
            for profile in $instance_profiles; do
                echo "      Removing from instance profile: $profile"
                aws iam remove-role-from-instance-profile --instance-profile-name "$profile" --role-name "$role" 2>/dev/null || echo "      Failed"
                echo "      Deleting instance profile: $profile"
                aws iam delete-instance-profile --instance-profile-name "$profile" 2>/dev/null || echo "      Failed"
            done
        fi
        
        # Detach managed policies
        echo "    Detaching managed policies..."
        attached_policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || echo "")
        if [ ! -z "$attached_policies" ]; then
            for policy_arn in $attached_policies; do
                echo "      Detaching: $policy_arn"
                aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn" 2>/dev/null || echo "      Failed"
            done
        fi
        
        # Delete inline policies
        echo "    Deleting inline policies..."
        inline_policies=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames[]' --output text 2>/dev/null || echo "")
        if [ ! -z "$inline_policies" ]; then
            for policy_name in $inline_policies; do
                echo "      Deleting: $policy_name"
                aws iam delete-role-policy --role-name "$role" --policy-name "$policy_name" 2>/dev/null || echo "      Failed"
            done
        fi
        
        # Delete role
        echo "    Deleting role: $role"
        aws iam delete-role --role-name "$role" 2>/dev/null || echo "    Failed to delete role"
    else
        echo "  Not found: $role"
    fi
done

# 5. Delete S3 buckets (empty first)
echo ""
echo "==> Deleting S3 Buckets..."
for bucket in "${ENV}-starttech-frontend-${ACCOUNT_ID}" "${ENV}-starttech-alb-logs-${ACCOUNT_ID}" "${ENV}-starttech-terraform-state-${ACCOUNT_ID}"; do
    if aws s3 ls "s3://$bucket" --region $AWS_REGION 2>/dev/null; then
        echo "  Processing bucket: $bucket"
        echo "    Emptying bucket..."
        aws s3 rm "s3://$bucket" --recursive --region $AWS_REGION 2>/dev/null || echo "    Failed to empty"
        
        echo "    Deleting all versions..."
        aws s3api delete-objects --bucket "$bucket" --region $AWS_REGION \
            --delete "$(aws s3api list-object-versions --bucket "$bucket" --region $AWS_REGION \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" 2>/dev/null || echo "    No versions to delete"
        
        echo "    Deleting delete markers..."
        aws s3api delete-objects --bucket "$bucket" --region $AWS_REGION \
            --delete "$(aws s3api list-object-versions --bucket "$bucket" --region $AWS_REGION \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" 2>/dev/null || echo "    No delete markers"
        
        echo "    Deleting bucket..."
        aws s3api delete-bucket --bucket "$bucket" --region $AWS_REGION 2>/dev/null || echo "    Failed to delete bucket"
    else
        echo "  Not found: $bucket"
    fi
done

# 6. Delete DynamoDB tables
echo ""
echo "==> Deleting DynamoDB Tables..."
for table in "${ENV}-starttech-terraform-locks"; do
    if aws dynamodb describe-table --table-name "$table" --region $AWS_REGION 2>/dev/null | grep -q "Table"; then
        echo "  Deleting: $table"
        aws dynamodb delete-table --table-name "$table" --region $AWS_REGION 2>/dev/null || echo "  Failed to delete"
        echo "  Waiting for deletion..."
        aws dynamodb wait table-not-exists --table-name "$table" --region $AWS_REGION 2>/dev/null || echo "  Wait timeout or failed"
    else
        echo "  Not found: $table"
    fi
done

# 7. Delete OIDC provider (last, in case other operations need it)
echo ""
echo "==> Deleting OIDC Provider..."
oidc_arn="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$oidc_arn" 2>/dev/null | grep -q "Url"; then
    echo "  Deleting: $oidc_arn"
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$oidc_arn" 2>/dev/null || echo "  Failed to delete"
else
    echo "  Not found: $oidc_arn"
fi

echo ""
echo "======================================"
echo "Cleanup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Verify all resources are deleted in AWS Console"
echo "2. Run: gh workflow run terraform-deploy.yml -f action=apply --ref main"
echo ""
