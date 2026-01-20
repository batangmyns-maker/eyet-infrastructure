# Ansible (AWS SSO + SSM)

이 디렉터리는 SSH 없이 **AWS Systems Manager(Session Manager, SSM)** 로 EC2에 접속해 서버 초기 세팅(예: git, docker)을 수행하기 위한 Ansible 구성을 포함합니다.

## 왜 SSM을 쓰나요?

- Terraform에서 EC2를 `key_name = null` 로 만들면 SSH KeyPair 없이 생성됩니다.
- 이 경우 SSH로 접속하기 어렵기 때문에, AWS SSO로 인증한 뒤 SSM을 통해 원격 명령을 실행하는 방식이 편합니다.

## 디렉터리 구조

- `ansible.cfg`
  - Ansible 기본 설정
- `inventory/dev.ini`
  - dev/prod 대상(EC2 instance id)과 SSM 설정
- `requirements.yml`
  - 필요한 Ansible collection 목록
- `playbooks/dev-setup.yml`
  - dev 서버 베이스라인 세팅 플레이북
- `roles/dev_server/`
  - dev 서버 베이스라인 세팅 role

## 사전 준비물

- AWS CLI 설치
- Ansible 설치
- AWS SSO 설정 완료 (`bt-sso` 프로파일 사용)

추가로, SSM 연결을 위해 다음이 필요합니다.

- EC2에 SSM Agent가 동작 중이어야 함
- EC2 IAM Role에 `AmazonSSMManagedInstanceCore` 권한이 있어야 함
- SSM 전송용 S3 버킷이 필요함 (SSM connection plugin이 모듈 파일 전송에 S3를 사용)
  - dev: `bt-portal-dev-file-transfer`
  - prod: `bt-portal-prod-file-transfer`

## 빠른 시작

### 1) AWS SSO 로그인

```powershell
aws sso login --profile bt-sso
```

### 2) Ansible collection 설치

```powershell
ansible-galaxy collection install -r ansible/requirements.yml
```

### 3) 대상 확인

`inventory/dev.ini`에는 다음과 같이 EC2 instance id가 들어갑니다.

- dev: `i-002da1c0e49e26022`
- prod: `i-07aefa63a7d840eba`

SSM 연결은 IP가 아니라 **instance id**로 붙습니다.

### 4) 플레이북 실행

dev에만 적용:

```powershell
wsl
ansible-playbook -i inventory/dev.ini playbooks/setup.yml --check
ansible-playbook -i inventory/dev.ini playbooks/setup.yml
```

prod에만 적용:

```powershell
wsl
ansible-playbook -i inventory/prod.ini playbooks/setup.yml --check
ansible-playbook -i inventory/prod.ini playbooks/setup.yml
```

## 핵심 개념 정리

### Inventory

- 호스트는 다음처럼 정의됩니다.
  - `ansible_host=i-...` (EC2 instance id)
- 그룹은 `dev`, `prod` 로 분리되어 있습니다.
- 공통 변수는 `[all:vars]` 에 들어갑니다.
- 그룹별 S3 버킷은 `[dev:vars]`, `[prod:vars]` 에서 지정합니다.

### SSM connection plugin (amazon.aws.aws_ssm)

`inventory/dev.ini`에서 다음 변수가 핵심입니다.

- `ansible_connection=amazon.aws.aws_ssm`
- `ansible_aws_ssm_region=ap-northeast-2`
- `ansible_aws_ssm_bucket_name=...`

주의:

- 이 플러그인은 모듈 전송을 위해 **S3 버킷이 필수**입니다.
- SSH처럼 `ansible_user`를 원격 계정 선택에 쓰는 방식이 아니라, 보통 `become_user`로 실행 유저를 맞춥니다.

### become / sudo

현재 inventory에서 다음처럼 설정합니다.

- `ansible_become=true`
- `ansible_become_user=ec2-user`

즉, SSM으로 접속한 뒤 작업은 `ec2-user` 권한으로 실행됩니다.

## 자주 나는 문제

### 1) Windows에서 AWS CLI가 'cat' 오류를 내는 경우

PowerShell에서 아래처럼 `--no-cli-pager`를 붙이면 해결됩니다.

```powershell
aws --no-cli-pager s3api list-buckets --profile bt-sso
```

### 2) SSM 접속이 안 되는 경우

- EC2가 SSM에 등록되어 있는지 확인
  - AWS Console > Systems Manager > Fleet Manager / Managed instances
- EC2가 외부로 나갈 수 있는지 확인
  - 퍼블릭 서브넷이면 IGW 통해 outbound 가능해야 함
  - 프라이빗이면 VPC Endpoint 구성이 필요할 수 있음

### 3) S3 접근 권한 오류

SSM 플러그인이 선택된 버킷에 업/다운로드를 수행합니다.

- 로컬에서 사용 중인 SSO 권한(현재 로그인한 역할)에 S3 접근 권한이 있는지
- EC2 인스턴스 Role에도 버킷 접근 권한이 필요한지

## 변경 포인트

- 설치 패키지/세팅 변경: `roles/dev_server/tasks/main.yml`
- dev/prod 대상 변경: `inventory/dev.ini`
- 공통 설정 추가: `roles/` 아래 role을 추가하고 플레이북 `roles:`에 연결
