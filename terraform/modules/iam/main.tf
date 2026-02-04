# Reference GitHub OIDC Provider (pre-created bootstrap resource)
# GitHub OIDC Provider (Re-created after nuke)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_thumbprint]
}

# IAM Role for GitHub Actions CI/CD (Frontend Deployment)
resource "aws_iam_role" "github_frontend_role" {
  name = "${var.environment}-github-frontend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_owner}/${var.github_repo_app}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Policy for Frontend Deployment (S3 + CloudFront)
resource "aws_iam_role_policy" "github_frontend_policy" {
  name = "${var.environment}-github-frontend-policy"
  role = aws_iam_role.github_frontend_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.frontend_bucket_arn,
          "${var.frontend_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"
      }
    ]
  })
}

# IAM Role for GitHub Actions CI/CD (Backend Deployment)
resource "aws_iam_role" "github_backend_role" {
  name = "${var.environment}-github-backend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_owner}/${var.github_repo_app}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Policy for Backend Deployment (ECR + CodeDeploy)
resource "aws_iam_role_policy" "github_backend_policy" {
  name = "${var.environment}-github-backend-policy"
  role = aws_iam_role.github_backend_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arn
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:ListApplications",
          "codedeploy:ListDeployments"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for GitHub Actions CI/CD (Infrastructure Deployment)
resource "aws_iam_role" "github_infra_role" {
  name = "${var.environment}-github-infra-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_owner}/${var.github_repo_infra}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Policy for Infrastructure Deployment (Terraform)
resource "aws_iam_role_policy" "github_infra_policy" {
  name = "${var.environment}-github-infra-policy"
  role = aws_iam_role.github_infra_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.terraform_locks_table}"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticache:*",
          "elasticloadbalancing:*",
          "s3:*",
          "cloudfront:*",
          "logs:*",
          "cloudwatch:*",
          "sns:*",
          "iam:*",
          "ecr:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM User for local development (if needed)
resource "aws_iam_user" "dev_user" {
  count = var.create_dev_user ? 1 : 0
  name  = "${var.environment}-starttech-dev"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-dev-user"
    }
  )
}

# Attach policies to dev user
resource "aws_iam_user_policy" "dev_user_policy" {
  count = var.create_dev_user ? 1 : 0
  name  = "${var.environment}-dev-user-policy"
  user  = aws_iam_user.dev_user[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "cloudfront:*",
          "ec2:*",
          "elasticache:*",
          "elasticloadbalancing:*",
          "logs:*",
          "cloudwatch:*",
          "ecr:*"
        ]
        Resource = "*"
      }
    ]
  })
}
