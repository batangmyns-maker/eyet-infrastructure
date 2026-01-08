terraform {
  backend "s3" {
    bucket         = "bt-portal-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "bt-portal-terraform-locks"
    encrypt        = true
  }
}
