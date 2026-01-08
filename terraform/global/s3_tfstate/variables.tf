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

variable "tfstate_bucket_name" {
  type = string
}

variable "tflock_table_name" {
  type = string
}
