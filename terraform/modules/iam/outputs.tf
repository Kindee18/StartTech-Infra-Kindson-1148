output "github_frontend_role_arn" {
  description = "ARN of the GitHub frontend deployment role"
  value       = aws_iam_role.github_frontend_role.arn
}

output "github_backend_role_arn" {
  description = "ARN of the GitHub backend deployment role"
  value       = aws_iam_role.github_backend_role.arn
}

output "github_infra_role_arn" {
  description = "ARN of the GitHub infrastructure deployment role"
  value       = aws_iam_role.github_infra_role.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = data.aws_iam_openid_connect_provider.github.arn
}

output "dev_user_name" {
  description = "Name of the dev IAM user"
  value       = try(aws_iam_user.dev_user[0].name, null)
}
