variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type    = string
  default = null
}

variable "terraform_role_arn" {
  type    = string
  default = null
}

variable "terraform_sso_principal_arn" {
  type    = string
  default = null
}

variable "terraform_bootstrap_principal_arn" {
  type    = string
  default = null
}

variable "domain_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "trusted_operator_cidrs" {
  type    = list(string)
  default = []
}

variable "ec2_instance_type" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "server_port" {
  type    = number
  default = 18082
}

variable "cloudfront_backend_port" {
  type    = number
  default = 80
}

variable "cors_allowed_origins" {
  type = list(string)
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

variable "toss_secret_key" {
  type      = string
  sensitive = true
}

variable "toss_security_key" {
  type      = string
  sensitive = true
}

variable "toss_billing_secret_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "toss_billing_security_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "openai_api_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "cloudfront_public_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "cloudfront_key_group_id" {
  type    = string
  default = null
}

variable "cloudfront_key_pair_id" {
  type    = string
  default = null
}

variable "cloudfront_private_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "identity_verification_key_file_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "identity_verification_client_prefix" {
  type      = string
  sensitive = true
  default   = null
}

variable "identity_verification_encryption_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
  default   = null
}

variable "enable_ses" {
  type    = bool
  default = false
}

variable "ses_verified_email_addresses" {
  type    = list(string)
  default = []
}

variable "ses_enable_dmarc" {
  type    = bool
  default = false
}

variable "ses_dmarc_email" {
  type    = string
  default = ""
}

variable "ses_dmarc_policy" {
  type    = string
  default = "none"
}

variable "ses_additional_domains" {
  type    = list(string)
  default = []
}

variable "alarm_email" {
  type      = string
  sensitive = true
}
