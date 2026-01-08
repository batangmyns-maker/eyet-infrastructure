terraform {
  backend "s3" {
    bucket         = "bt-portal-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "bt-portal-terraform-locks-dev"
    encrypt        = true
  }
}
