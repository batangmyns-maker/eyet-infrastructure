data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

variable "github_actions_backend_repo" {
  type        = string
  description = "GitHub repository in the form 'owner/repo' (NOT a URL). Example: batangmyns-maker/eyet-backend"
}

variable "github_actions_backend_branch" {
  type    = string
  default = "dev-release"
}

resource "aws_iam_role" "github_actions_backend_deploy" {
  name = "${var.project_name}-${var.environment}-github-actions-backend-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_actions_backend_repo}:ref:refs/heads/${var.github_actions_backend_branch}",
              "repo:${var.github_actions_backend_repo}:environment:${var.environment}"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_backend_deploy" {
  name = "${var.project_name}-${var.environment}-github-actions-backend-deploy"

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
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/bt-portal-backend-dev"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.deploy_artifacts.arn}/bt-portal-backend/dev/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.deploy_artifacts.arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "bt-portal-backend/dev/*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_backend_deploy" {
  role       = aws_iam_role.github_actions_backend_deploy.name
  policy_arn = aws_iam_policy.github_actions_backend_deploy.arn
}

output "github_actions_backend_deploy_role_arn" {
  value = aws_iam_role.github_actions_backend_deploy.arn
}
