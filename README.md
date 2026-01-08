# 운영 환경

cd terraform/global/s3_tfstate
terraform init
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"

cd terraform/enviroments/prod
terraform init
terraform plan
terraform apply

# 개발 환경

cd terraform/global/s3_tfstate
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

cd terraform/enviroments/dev
terraform init
terraform plan
terraform apply
