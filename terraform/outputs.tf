output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.compute.alb_arn
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

output "frontend_bucket_name" {
  description = "Frontend S3 bucket name"
  value       = module.storage.frontend_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.storage.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.storage.cloudfront_domain_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "mongodb_connection_string" {
  description = "MongoDB connection string"
  value       = module.database.mongodb_connection_string
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.caching.redis_endpoint
}

output "redis_url" {
  description = "Redis connection URL"
  value       = module.caching.redis_url
}

output "backend_log_group_name" {
  description = "CloudWatch log group name for backend"
  value       = module.monitoring.backend_log_group_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.monitoring.sns_topic_arn
}

output "github_frontend_role_arn" {
  description = "GitHub frontend deployment role ARN"
  value       = module.iam.github_frontend_role_arn
}

output "github_backend_role_arn" {
  description = "GitHub backend deployment role ARN"
  value       = module.iam.github_backend_role_arn
}

output "github_infra_role_arn" {
  description = "GitHub infrastructure deployment role ARN"
  value       = module.iam.github_infra_role_arn
}

output "terraform_state_bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = module.storage.terraform_state_bucket_name
}

output "terraform_locks_table_name" {
  description = "Terraform locks DynamoDB table name"
  value       = module.storage.terraform_locks_table_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "ec2_iam_role_name" {
  description = "IAM role name for EC2 instances"
  value       = module.compute.iam_role_name
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = module.iam.github_oidc_provider_arn
}
