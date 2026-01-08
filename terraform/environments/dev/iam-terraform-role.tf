resource "aws_iam_role" "terraform" {
  count = (var.terraform_sso_principal_arn == null && var.terraform_bootstrap_principal_arn == null) ? 0 : 1

  name = "${var.project_name}-${var.environment}-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeFromSsoPrincipal"
        Effect = "Allow"
        Principal = {
          AWS = var.terraform_sso_principal_arn != null ? var.terraform_sso_principal_arn : var.terraform_bootstrap_principal_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = var.trusted_operator_cidrs
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-terraform-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  count = (var.terraform_sso_principal_arn == null && var.terraform_bootstrap_principal_arn == null) ? 0 : 1

  role       = aws_iam_role.terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "terraform_execution_role_arn" {
  value = (var.terraform_sso_principal_arn == null && var.terraform_bootstrap_principal_arn == null) ? null : aws_iam_role.terraform[0].arn
}
