# 운영환경 tfstate 생성

terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"

# 개발환경 tfstate 생성

te
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
