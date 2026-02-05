terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.15"
    }
  }

  # Remote state backend
  backend "s3" {
    bucket         = "dev-starttech-terraform-state-125168806853"
    key            = "starttech/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dev-starttech-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "StartTech"
      ManagedBy   = "Terraform"
    }
  }
}

provider "mongodbatlas" {
  public_key  = var.mongodb_public_key
  private_key = var.mongodb_private_key
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  backend_port         = var.backend_port
  ssh_allowed_cidrs    = var.ssh_allowed_cidrs
  common_tags          = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  environment = var.environment
  common_tags = local.common_tags
}

# Compute Module (ALB, ASG, EC2)
module "compute" {
  source = "./modules/compute"

  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  private_subnet_ids         = module.networking.private_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  ec2_security_group_id      = module.networking.ec2_security_group_id
  backend_port               = var.backend_port
  instance_type              = var.instance_type
  min_size                   = var.min_size
  max_size                   = var.max_size
  desired_capacity           = var.desired_capacity
  health_check_path          = var.health_check_path
  docker_image               = var.docker_image
  log_group_name             = module.monitoring.backend_log_group_name
  aws_region                 = var.aws_region
  aws_account_id             = data.aws_caller_identity.current.account_id
  ecr_repository_arn         = aws_ecr_repository.backend.arn
  redis_endpoint             = "${module.caching.redis_endpoint}:${module.caching.redis_port}"
  mongodb_connection_string  = module.database.mongodb_connection_string
  mongodb_db_name            = module.database.mongodb_database_name
  jwt_secret_key             = var.jwt_secret_key
  enable_deletion_protection = var.enable_alb_deletion_protection
  common_tags                = local.common_tags
}

# Database Module (MongoDB Atlas or RDS)
module "database" {
  source = "./modules/database"

  use_mongodb_atlas     = var.use_mongodb_atlas
  environment           = var.environment
  mongodb_org_id        = var.mongodb_org_id
  mongodb_project_id    = var.mongodb_project_id
  mongodb_region        = var.mongodb_region
  mongodb_instance_type = var.mongodb_instance_type
  mongodb_version       = var.mongodb_version
  mongodb_num_shards    = var.mongodb_num_shards
  mongodb_username      = var.mongodb_username
  mongodb_password      = var.mongodb_password
  ec2_mongodb_host      = "mongodb.internal"
  common_tags           = local.common_tags
}

# Caching Module (ElastiCache Redis)
module "caching" {
  source = "./modules/caching"

  environment             = var.environment
  private_subnet_ids      = module.networking.private_subnet_ids
  security_group_id       = module.networking.elasticache_security_group_id
  node_type               = var.redis_node_type
  num_cache_nodes         = var.redis_num_cache_nodes
  engine_version          = var.redis_engine_version
  auth_token              = var.redis_auth_token
  snapshot_retention_days = var.redis_snapshot_retention_days
  snapshot_window         = var.redis_snapshot_window
  maintenance_window      = var.redis_maintenance_window
  log_retention_days      = var.log_retention_days
  common_tags             = local.common_tags
}

# Monitoring Module (CloudWatch, Alarms, Dashboards)
module "monitoring" {
  source = "./modules/monitoring"

  environment        = var.environment
  log_retention_days = var.log_retention_days
  enable_alb_logs    = var.enable_alb_logs
  common_tags        = local.common_tags
}

# IAM Module (GitHub OIDC, Roles, Policies)
module "iam" {
  source = "./modules/iam"

  environment                = var.environment
  aws_account_id             = data.aws_caller_identity.current.account_id
  aws_region                 = var.aws_region
  github_repo_owner          = var.github_repo_owner
  github_repo_app            = var.github_repo_app
  github_repo_infra          = var.github_repo_infra
  github_branch              = var.github_branch
  github_thumbprint          = var.github_thumbprint
  frontend_bucket_arn        = module.storage.frontend_bucket_arn
  cloudfront_distribution_id = module.storage.cloudfront_distribution_id
  ecr_repository_arn         = aws_ecr_repository.backend.arn
  terraform_state_bucket     = module.storage.terraform_state_bucket_name
  terraform_locks_table      = module.storage.terraform_locks_table_name
  create_dev_user            = var.create_dev_user
  common_tags                = local.common_tags
}

# Reference ECR Repository (pre-created bootstrap resource)
# ECR Repository (Re-created after nuke)
resource "aws_ecr_repository" "backend" {
  name                 = "${var.environment}-starttech-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Get current AWS account ID and caller identity
data "aws_caller_identity" "current" {}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = "StartTech"
    ManagedBy   = "Terraform"
  }
}
