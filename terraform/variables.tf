variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Compute Variables
variable "backend_port" {
  description = "Port for backend API"
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/health"
}

variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "docker_image" {
  description = "Docker image URL for backend"
  type        = string
}

variable "jwt_secret_key" {
  description = "JWT secret key for backend"
  type        = string
  sensitive   = true
  default     = ""
}

# Database Variables
variable "use_mongodb_atlas" {
  description = "Use MongoDB Atlas (true) or self-hosted MongoDB (false)"
  type        = bool
  default     = false
}

variable "mongodb_org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
  default     = ""
}

variable "mongodb_project_id" {
  description = "MongoDB Atlas Project ID (optional, if using existing project)"
  type        = string
  default     = ""
}

variable "mongodb_region" {
  description = "MongoDB Atlas region"
  type        = string
  default     = "US_EAST_1"
}

variable "mongodb_instance_type" {
  description = "MongoDB Atlas instance type"
  type        = string
  default     = "M5"
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
  default     = "7.0"
}

variable "mongodb_num_shards" {
  description = "Number of shards for MongoDB cluster"
  type        = number
  default     = 1
}

variable "mongodb_username" {
  description = "MongoDB database username"
  type        = string
  sensitive   = true
}

variable "mongodb_password" {
  description = "MongoDB database password"
  type        = string
  sensitive   = true
}

variable "mongodb_public_key" {
  description = "MongoDB Atlas public API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mongodb_private_key" {
  description = "MongoDB Atlas private API key"
  type        = string
  sensitive   = true
  default     = ""
}

# Caching Variables
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_auth_token" {
  description = "Redis auth token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "redis_snapshot_retention_days" {
  description = "Redis snapshot retention days"
  type        = number
  default     = 5
}

variable "redis_snapshot_window" {
  description = "Redis snapshot window"
  type        = string
  default     = "03:00-04:00"
}

variable "redis_maintenance_window" {
  description = "Redis maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

# Monitoring Variables
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_alb_logs" {
  description = "Enable ALB logging to S3"
  type        = bool
  default     = true
}

# IAM Variables
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
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "create_dev_user" {
  description = "Create IAM user for local development"
  type        = bool
  default     = false
}
