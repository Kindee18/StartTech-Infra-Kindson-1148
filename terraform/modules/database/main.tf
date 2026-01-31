terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.15"
    }
  }
}

# MongoDB Atlas Project (if using managed MongoDB)
# Note: This requires MongoDB Atlas API key and organization ID to be set as environment variables
# export MONGODB_ATLAS_PUBLIC_KEY=xxx
# export MONGODB_ATLAS_PRIVATE_KEY=xxx

# Terraform provider configuration for MongoDB Atlas
# Add this to your provider configuration in main.tf:
# provider "mongodbatlas" {
#   public_key  = var.mongodb_public_key
#   private_key = var.mongodb_private_key
# }

# MongoDB Atlas Project
resource "mongodbatlas_project" "starttech" {
  count = var.use_mongodb_atlas ? 1 : 0
  
  name   = "${var.environment}-starttech"
  org_id = var.mongodb_org_id

  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
    }
  )
}

# MongoDB Atlas Cluster
resource "mongodbatlas_cluster" "starttech" {
  count = var.use_mongodb_atlas ? 1 : 0
  
  project_id = mongodbatlas_project.starttech[0].id
  name       = "${var.environment}-starttech-cluster"
  
  # Cluster configuration
  provider_name               = "AWS"
  provider_region_name        = var.mongodb_region
  provider_instance_size_name = var.mongodb_instance_type
  
  # Database version
  mongo_db_major_version = var.mongodb_version
  
  # Backup
  backup_enabled                  = true
  auto_scaling_disk_gb_enabled    = true
  auto_scaling_compute_scale_down_enabled = true
  
  # High availability
  num_shards = var.mongodb_num_shards
  
  # tags = var.common_tags  # Not supported in MongoDB Atlas provider
}

# MongoDB Atlas Database User
resource "mongodbatlas_database_user" "starttech_app" {
  count = var.use_mongodb_atlas ? 1 : 0
  
  project_id         = mongodbatlas_project.starttech[0].id
  auth_database_name = "admin"
  username           = var.mongodb_username
  password           = var.mongodb_password
  
  roles {
    role_name     = "readWrite"
    database_name = "starttech"
  }
  
  roles {
    role_name     = "readWrite"
    database_name = "starttech_staging"
  }
}

# MongoDB Atlas IP Whitelist (commented - use API to configure separately)
# resource "mongodbatlas_project_ip_allowlist" "ec2_instances" {
#   count = var.use_mongodb_atlas ? 1 : 0
#   
#   project_id = mongodbatlas_project.starttech[0].id
#   ip_address = "0.0.0.0/0"
#   comment    = "Allow EC2 instances to connect to MongoDB Atlas"
# }

# Connection String output for application
locals {
  mongodb_connection_string = var.use_mongodb_atlas ? (
    "mongodb+srv://${var.mongodb_username}:${urlencode(var.mongodb_password)}@${mongodbatlas_cluster.starttech[0].connection_strings[0].standard_srv}/?retryWrites=true&w=majority"
  ) : (
    "mongodb://${var.mongodb_username}:${urlencode(var.mongodb_password)}@${var.ec2_mongodb_host}:27017/starttech"
  )
}

# RDS Option: Self-hosted MongoDB on EC2 (Alternative to Atlas)
# If using EC2-hosted MongoDB, ensure:
# 1. MongoDB is installed on EC2 instances
# 2. Security group allows port 27017 from app instances
# 3. Database is properly initialized with users and databases
