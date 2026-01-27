output "mongodb_connection_string" {
  description = "MongoDB connection string for application"
  value       = local.mongodb_connection_string
  sensitive   = true
}

output "mongodb_host" {
  description = "MongoDB host"
  value = var.use_mongodb_atlas ? (
    try(mongodbatlas_cluster.starttech[0].connection_strings[0].standard_srv, "")
  ) : var.ec2_mongodb_host
}

output "mongodb_port" {
  description = "MongoDB port"
  value       = 27017
}

output "mongodb_database_name" {
  description = "MongoDB database name"
  value       = "starttech"
}
