# AWS SSO 로그인

aws sso login --profile bt-sso

# terraform

## 운영 환경

cd terraform/enviroments/prod
terraform init
terraform plan
terraform apply -var-file="prod.tfvars"

cd terraform/enviroments/prod
terraform init
terraform plan
terraform apply

## 개발 환경

cd terraform/enviroments/dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

cd terraform/enviroments/dev
terraform init
terraform plan
terraform apply

# Ansible

## 디렉토리 구조

- inventory/dev.ini: ec2 식별정보, 변수 기술
- playbooks/dev-setup.yml: 명령 실행 위치, 서버 상태 확인, roles 밑의 어떤 디렉토리를 참고할지 정하며 ansible-playbook 명령어에 대한 정보 기술

wsl
aws sso login

## 개발 환경

ansible-playbook playbooks/setup.yml -i inventory/dev.ini -e target=dev --check
ansible-playbook playbooks/setup.yml -i inventory/dev.ini -e target=dev

## 운영 환경

ansible-playbook -i inventory/prod.ini playbooks/setup.yml -e target=prod --check

ansible-playbook -i inventory/prod.ini playbooks/setup.yml -e target=prod
