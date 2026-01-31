variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "Kindee18"
}

variable "github_repo_app" {
  description = "GitHub application repository name"
  type        = string
  default     = "StartTech-Kindson-1148"
}

variable "github_repo_infra" {
  description = "GitHub infrastructure repository name"
  type        = string
  default     = "StartTech-Infra-Kindson-1148"
}

variable "github_branch" {
  description = "GitHub branch to allow OIDC from"
  type        = string
  default     = "main"
}

variable "github_thumbprint" {
  description = "GitHub OIDC thumbprint"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1" # Current GitHub thumbprint
}

variable "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "terraform_locks_table" {
  description = "DynamoDB table for Terraform locks"
  type        = string
}

variable "create_dev_user" {
  description = "Create IAM user for local development"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
