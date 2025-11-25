# 🏗️ BT Portal Infrastructure

AWS 기반 풀스택 웹 애플리케이션 인프라 (Terraform)

## 📋 프로젝트 구조

```
bt-portal-infrastructure/
├── terraform/
│   ├── environments/
│   │   └── prod/                    # 운영 환경
│   │       ├── main.tf              # 메인 설정
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars     # 실제 변수 값 (Git 제외)
│   └── modules/
│       ├── vpc/                     # VPC, 서브넷, NAT
│       ├── security-groups/         # 보안 그룹
│       ├── rds/                     # PostgreSQL 데이터베이스
│       ├── s3/                      # 정적 파일 & 업로드
│       ├── cloudfront/              # CDN
│       ├── route53/                 # DNS
│       ├── acm/                     # SSL 인증서
│       ├── ec2/                     # 백엔드 서버
│       └── secrets-manager/         # 🔐 민감 정보 관리 (NEW!)
├── scripts/
│   ├── setup-backend.sh            # 백엔드 초기 설정
│   ├── deploy-backend.sh           # 백엔드 배포
│   └── deploy-frontend.sh          # 프론트엔드 배포
├── QUICK_START.md                  # 빠른 시작 가이드
├── DEPLOYMENT_GUIDE.md             # 배포 가이드
├── SECRETS_MANAGEMENT.md           # 🔐 보안 관리 가이드 (NEW!)
└── README.md                       # 이 파일
```

## 🎯 주요 기능

### 인프라 구성

- ☁️ **VPC**: 2개 가용 영역, Public/Private 서브넷
- 🔒 **보안**: Secrets Manager를 통한 민감 정보 암호화 관리
- 🗄️ **RDS**: PostgreSQL (Multi-AZ, 자동 백업)
- 🚀 **EC2**: Docker 기반 백엔드 서버
- 📦 **S3**: 프론트엔드 호스팅, 파일 업로드
- 🌐 **CloudFront**: 글로벌 CDN
- 📡 **Route53**: DNS 관리
- 🔐 **ACM**: SSL/TLS 인증서

### 🆕 보안 강화 (2025-11-25 업데이트)

**AWS Secrets Manager 통합:**
- ✅ DB 비밀번호 암호화 저장
- ✅ JWT 시크릿 키 보안 관리
- ✅ Toss Payments API 키 보호
- ✅ 자동 로테이션 지원
- ✅ IAM 기반 접근 제어
- ✅ CloudTrail 감사 로그

자세한 내용: [📚 Secrets Manager 가이드](./SECRETS_MANAGEMENT.md)

## 🚀 빠른 시작

### 1. 사전 요구사항

- [Terraform](https://www.terraform.io/downloads) v1.0+
- AWS CLI 설치 및 설정
- AWS 계정 및 IAM 권한
- 도메인 (Route53 또는 다른 등록기관)

### 2. 초기 설정

```bash
# 1. 저장소 클론
git clone <repository-url>
cd bt-portal-infrastructure

# 2. Terraform 변수 설정
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # 실제 값으로 수정

# 🔐 중요: 민감한 정보는 Secrets Manager가 자동으로 암호화합니다
# - db_password: 강력한 비밀번호 (20자 이상)
# - jwt_secret_key: 무작위 문자열 (64자 이상)
# - toss_secret_key: Toss 개발자센터에서 발급

# 3. Terraform 초기화
terraform init

# 4. 인프라 배포
terraform plan    # 변경사항 확인
terraform apply   # 실제 배포
```

### 3. 배포 후 확인

```bash
# 출력된 정보 확인
terraform output

# Secrets Manager 확인
aws secretsmanager list-secrets --region ap-northeast-2
```

## 📖 문서

### 시작 가이드
- **[빠른 시작 가이드](./QUICK_START.md)** - 처음 시작하는 분들을 위한 단계별 가이드
- **[배포 가이드](./DEPLOYMENT_GUIDE.md)** - 백엔드/프론트엔드 배포 방법

### 보안 관리 (중요! 🔐)
- **[Secrets Manager 가이드](./SECRETS_MANAGEMENT.md)** - 민감 정보 관리 방법
- **[🔥 Spring Boot 통합 가이드](./SPRING_SECRETS_MANAGER_GUIDE.md)** - 백엔드 개발자 필독!
- **[Spring Boot 마이그레이션](./SPRING_SECRETS_MIGRATION.md)** - 단계별 적용 가이드

### 운영 가이드
- **[IAM 사용자 생성](./GUIDE-CREATE-IAM-USER.md)** - AWS IAM 설정
- **[인스턴스 크기 변경](./GUIDE-RESIZE-INSTANCES.md)** - EC2/RDS 스펙 조정

### 템플릿
- **[Docker Compose 템플릿](./templates/)** - 로컬/운영 환경별 설정

## 🔐 보안 권장사항

### ✅ 필수

1. **Secrets Manager 사용** (이미 적용됨)
   - DB 비밀번호, API 키 등 암호화 저장
   - 정기적인 로테이션 권장

2. **terraform.tfvars 보안**
   ```bash
   # .gitignore에 추가 (이미 되어있음)
   echo "terraform.tfvars" >> .gitignore
   ```

3. **강력한 비밀번호**
   - DB: 20자 이상 (대소문자, 숫자, 특수문자)
   - JWT: 64자 이상 무작위 문자열

4. **SSH 접근 제한**
   ```hcl
   allowed_ssh_cidrs = ["YOUR_IP/32"]  # 실제 IP만 허용
   ```

5. **Terraform 상태 파일 암호화**
   - S3 백엔드 암호화 활성화 (이미 되어있음)
   - DynamoDB 잠금으로 동시 실행 방지

### 📊 권장

- CloudWatch 알람 설정
- AWS GuardDuty 활성화
- VPC Flow Logs 활성화
- 정기적인 보안 패치

## 💰 비용 예상 (월 기준)

### 최소 구성 (t3.small)
- **EC2** (t3.small): ~$15
- **RDS** (db.t3.small): ~$25
- **NAT Gateway**: ~$32
- **CloudFront**: ~$1-5 (트래픽에 따라)
- **S3**: ~$1-3
- **Route53**: ~$0.50
- **🆕 Secrets Manager**: ~$1.20 (3개 시크릿)
- **기타** (데이터 전송 등): ~$5-10

**총 예상 비용: $80-90/월** (약 ₩110,000/월)

### 운영 권장 구성 (t3.medium)
- **EC2** (t3.medium): ~$30
- **RDS** (db.t3.medium, Multi-AZ): ~$70
- **기타 동일**

**총 예상 비용: $140-150/월** (약 ₩190,000/월)

> 💡 **비용 절감 팁**: 
> - 개발 환경은 Parameter Store (무료) 사용
> - Reserved Instance로 EC2/RDS 비용 30-50% 절감
> - NAT Gateway 대신 NAT Instance 사용 (비용 50% 절감)

## 🛠️ 주요 명령어

```bash
# Terraform
terraform init          # 초기화
terraform plan          # 변경사항 미리보기
terraform apply         # 인프라 배포
terraform destroy       # 인프라 삭제 (주의!)
terraform output        # 출력 값 확인

# Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id /bt-portal/prod/db/credentials \
  --query 'SecretString' --output text | jq

aws secretsmanager update-secret \
  --secret-id /bt-portal/prod/jwt/secret-key \
  --secret-string "new-secret"

# 배포
./scripts/setup-backend.sh          # 백엔드 초기 설정
./scripts/deploy-backend.sh         # 백엔드 배포
./scripts/deploy-frontend.sh        # 프론트엔드 배포
```

## 🔄 업데이트 내역

### v2.1 (2025-11-25) - Spring Boot 직접 통합 ⭐ 최신
- ✅ Spring Boot에서 Secrets Manager 직접 조회
- ✅ .env 파일 제거 (디스크 평문 없음)
- ✅ 로컬/운영 환경 분리 (Profile 기반)
- ✅ 시크릿 변경 시 컨테이너 재시작만으로 적용
- ✅ docker-compose 템플릿 제공
- ✅ 완전한 마이그레이션 가이드

### v2.0 (2025-11-25) - 보안 강화
- ✅ AWS Secrets Manager 통합
- ✅ 민감 정보 암호화 저장
- ✅ IAM 정책 업데이트
- ✅ user-data 보안 개선
- ✅ 문서 업데이트

### v1.0 (이전)
- VPC, EC2, RDS, S3, CloudFront 기본 구성

## 📞 문제 해결

### 자주 묻는 질문

**Q: Secrets Manager 비용이 부담스러워요**
> A: 개발 환경은 무료인 Parameter Store를 사용하세요. 운영 환경만 Secrets Manager 사용을 권장합니다.

**Q: 시크릿 값을 어떻게 확인하나요?**
> A: AWS CLI 또는 콘솔에서 확인 가능합니다. [Secrets Manager 가이드](./SECRETS_MANAGEMENT.md#문제-해결) 참고

**Q: DB 비밀번호를 변경하고 싶어요**
> A: [시크릿 업데이트 방법](./SECRETS_MANAGEMENT.md#시크릿-업데이트-방법) 참고

**Q: Terraform 상태 파일이 손상되었어요**
> A: S3 백엔드에 자동 백업되어 있습니다. `terraform state pull`로 확인

더 많은 문제 해결: [Secrets Manager 가이드](./SECRETS_MANAGEMENT.md#문제-해결)

## 🤝 기여

이슈나 개선사항이 있다면 언제든 Issue를 열어주세요!

## 📄 라이선스

이 프로젝트는 프라이빗 프로젝트입니다.

---

**최근 업데이트**: 2025-11-25 (Secrets Manager 통합)

