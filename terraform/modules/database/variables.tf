variable "use_mongodb_atlas" {
  description = "Use MongoDB Atlas (true) or self-hosted MongoDB (false)"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name"
  type        = string
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
  description = "MongoDB Atlas instance type (M0, M2, M5, M10, M20, M30, etc.)"
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

variable "ec2_mongodb_host" {
  description = "EC2 hostname for self-hosted MongoDB (if not using Atlas)"
  type        = string
  default     = "mongodb.internal"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
