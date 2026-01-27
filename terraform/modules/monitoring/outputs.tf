output "backend_log_group_name" {
  description = "CloudWatch log group name for backend"
  value       = aws_cloudwatch_log_group.backend.name
}

output "alb_log_group_name" {
  description = "CloudWatch log group name for ALB"
  value       = aws_cloudwatch_log_group.alb.name
}

output "alb_logs_bucket_name" {
  description = "S3 bucket name for ALB logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_url" {
  description = "URL to CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
