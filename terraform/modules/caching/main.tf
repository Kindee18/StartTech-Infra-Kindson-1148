# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-elasticache-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-elasticache-subnet-group"
    }
  )
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-redis"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  engine_version       = var.engine_version
  port                 = 6379
  
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [var.security_group_id]
  
  # Backup configuration
  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window
  
  # Logs
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-redis"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.redis_slow_log,
    aws_cloudwatch_log_group.redis_engine_log
  ]
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis7"
  name   = "${var.environment}-redis-params"

  # Performance tuning parameters
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"  # Evict LRU keys when memory limit is reached
  }

  parameter {
    name  = "timeout"
    value = "300"  # Connection idle timeout
  }

  parameter {
    name  = "tcp-keepalive"
    value = "60"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-redis-params"
    }
  )
}

# CloudWatch Log Group for Slow Log
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.environment}/redis/slow-log"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-redis-slow-log"
    }
  )
}

# CloudWatch Log Group for Engine Log
resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${var.environment}/redis/engine-log"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-redis-engine-log"
    }
  )
}

# CloudWatch Metric Alarm - CPU Utilization
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.environment}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Alert when Redis CPU is high"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }
}

# CloudWatch Metric Alarm - Memory Utilization
resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.environment}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Alert when Redis memory usage is high"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }
}

# CloudWatch Metric Alarm - Evictions
resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  alarm_name          = "${var.environment}-redis-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "Alert when Redis is evicting keys"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.cluster_id
  }
}
