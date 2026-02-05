# StartTech Infrastructure Terraform Variables
# Configured for AWS Account: 125168806853

aws_region  = "us-east-1"
environment = "dev"

# Networking
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
ssh_allowed_cidrs    = ["0.0.0.0/0"] # TODO: Restrict to your IP in production

# Compute
jwt_secret_key                 = "super-secret-key-123"
backend_port                   = 8080
instance_type                  = "t3.micro"
min_size                       = 2
max_size                       = 6
desired_capacity               = 2
health_check_path              = "/health"
enable_alb_deletion_protection = false
docker_image                   = "125168806853.dkr.ecr.us-east-1.amazonaws.com/dev-starttech-backend:latest"

# Database - MongoDB Atlas
use_mongodb_atlas     = true
mongodb_org_id        = ""
mongodb_project_id    = "6981b6e450f691990e6a1292"
mongodb_region        = "US_EAST_1"
mongodb_instance_type = "M0" # Free tier for testing
mongodb_version       = "8.0"
mongodb_num_shards    = 1
mongodb_username      = "starttech_app"
mongodb_password      = "ChangeMe123!" # TODO: Change this!
mongodb_public_key    = "oiqjrbih"
mongodb_private_key   = "1e906836-2ae4-48b4-a4a0-a2a47aa0b849"

# Caching - Redis
redis_node_type               = "cache.t3.micro"
redis_num_cache_nodes         = 1
redis_engine_version          = "7.0"
redis_auth_token              = "" # Leave empty for dev, set in production
redis_snapshot_retention_days = 5
redis_snapshot_window         = "03:00-04:00"
redis_maintenance_window      = "mon:04:00-mon:05:00"

# Monitoring
log_retention_days = 30
enable_alb_logs    = true

# IAM - GitHub
github_repo_owner = "Kindee18"
github_repo_app   = "StartTech-Kindson-1148"
github_repo_infra = "StartTech-Infra-Kindson-1148"
github_branch     = "main"
github_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"
create_dev_user   = false
