# 백엔드 배포 가이드

## 📋 개요

이 문서는 AWS EC2 인스턴스에 Docker를 사용하여 백엔드 애플리케이션을 배포하는 방법을 설명합니다.

---

## 🔐 접속 정보

### EC2 인스턴스
- **인스턴스 ID**: `i-001fffed92260e57a`
- **Public IP**: `13.124.86.217`
- **접속 방법**: AWS Session Manager (SSH 키 불필요)

### EC2 접속 방법

#### 1. AWS CLI를 통한 Session Manager 접속
```bash
aws ssm start-session --target i-001fffed92260e57a --region ap-northeast-2
```

#### 2. AWS Console을 통한 접속
1. AWS Console → EC2 → 인스턴스 선택
2. "연결" 버튼 클릭
3. "Session Manager" 탭 선택
4. "연결" 클릭

---

## 🗄️ 데이터베이스 정보

### RDS PostgreSQL
- **엔드포인트**: `bt-portal-prod-postgres.cb8q6s28g4gg.ap-northeast-2.rds.amazonaws.com`
- **포트**: `5432`
- **데이터베이스명**: `btportal`
- **사용자명**: `postgres`
- **비밀번호**: `terraform.tfvars` 파일의 `db_password` 값 확인
  - 현재 값: `BtPortal2024!Prod` (실제 비밀번호로 변경 권장)

### 데이터베이스 연결 문자열
```
postgresql://postgres:BtPortal2024!Prod@bt-portal-prod-postgres.cb8q6s28g4gg.ap-northeast-2.rds.amazonaws.com:5432/btportal
```

---

## 🔑 AWS Secrets Manager

애플리케이션에서 사용할 시크릿 정보는 AWS Secrets Manager에 저장되어 있습니다.

### 시크릿 ARN 목록
- **DB 자격증명**: `/bt-portal/prod/db`
- **JWT 시크릿**: `/bt-portal/prod/jwt`
- **Toss Payments 시크릿**: `/bt-portal/prod/toss`

### Secrets Manager에서 값 조회
```bash
# DB 자격증명 조회
aws secretsmanager get-secret-value \
  --secret-id /bt-portal/prod/db \
  --region ap-northeast-2 \
  --query SecretString \
  --output text

# JWT 시크릿 조회
aws secretsmanager get-secret-value \
  --secret-id /bt-portal/prod/jwt \
  --region ap-northeast-2 \
  --query SecretString \
  --output text

# Toss Payments 시크릿 조회
aws secretsmanager get-secret-value \
  --secret-id /bt-portal/prod/toss \
  --region ap-northeast-2 \
  --query SecretString \
  --output text
```

---

## 🪣 S3 버킷 정보

### 버킷 목록
- **프론트엔드**: `bt-portal-prod-frontend`
- **관리자**: `bt-portal-prod-admin`
- **업로드 파일**: `bt-portal-prod-uploads`

### S3 접근 권한
EC2 인스턴스는 IAM 역할을 통해 다음 권한을 가지고 있습니다:
- `s3:PutObject` - 파일 업로드
- `s3:GetObject` - 파일 다운로드
- `s3:DeleteObject` - 파일 삭제
- `s3:ListBucket` - 버킷 목록 조회

---

## 🌐 CloudFront URL

### 배포된 서비스 URL
- **프론트엔드**: https://d1b1usg810fogj.cloudfront.net
- **관리자**: https://d1idoail4yv1n8.cloudfront.net
- **API**: https://dxiy3sxobi0f3.cloudfront.net
- **CDN (업로드 파일)**: https://d26b61xscm73kk.cloudfront.net

---

## 🐳 Docker 배포 가이드

### 1. EC2 인스턴스 접속
```bash
aws ssm start-session --target i-001fffed92260e57a --region ap-northeast-2
```

### 2. Docker 설치 확인
```bash
docker --version
docker-compose --version
```

### 3. 환경 변수 설정

EC2 인스턴스에 접속한 후, 다음 환경 변수를 설정합니다:

```bash
# 데이터베이스 설정
export DB_HOST=bt-portal-prod-postgres.cb8q6s28g4gg.ap-northeast-2.rds.amazonaws.com
export DB_PORT=5432
export DB_NAME=btportal
export DB_USERNAME=postgres
export DB_PASSWORD=BtPortal2024!Prod

# 애플리케이션 설정
export SERVER_PORT=18082
export AWS_REGION=ap-northeast-2

# Secrets Manager ARN
export DB_SECRET_ARN=arn:aws:secretsmanager:ap-northeast-2:873240210647:secret:/bt-portal/prod/db-CR1Hcz
export JWT_SECRET_ARN=arn:aws:secretsmanager:ap-northeast-2:873240210647:secret:/bt-portal/prod/jwt-mPOCpx
export TOSS_SECRET_ARN=arn:aws:secretsmanager:ap-northeast-2:873240210647:secret:/bt-portal/prod/toss-UNCi2x

# S3 버킷 설정
export S3_UPLOADS_BUCKET=bt-portal-prod-uploads
export S3_FRONTEND_BUCKET=bt-portal-prod-frontend
export S3_ADMIN_BUCKET=bt-portal-prod-admin

# CORS 설정
export CORS_ALLOWED_ORIGINS=*

# CloudFront URL
export FRONTEND_URL=https://d1b1usg810fogj.cloudfront.net
export ADMIN_URL=https://d1idoail4yv1n8.cloudfront.net
export API_URL=https://dxiy3sxobi0f3.cloudfront.net
export CDN_URL=https://d26b61xscm73kk.cloudfront.net
```

### 4. 환경 변수 파일 생성 (권장)

`.env` 파일을 생성하여 환경 변수를 관리하는 것을 권장합니다:

```bash
cat > /home/ec2-user/.env << EOF
# 데이터베이스 설정
DB_HOST=bt-portal-prod-postgres.cb8q6s28g4gg.ap-northeast-2.rds.amazonaws.com
DB_PORT=5432
DB_NAME=btportal
DB_USERNAME=postgres
DB_PASSWORD=BtPortal2024!Prod

# 애플리케이션 설정
SERVER_PORT=18082
AWS_REGION=ap-northeast-2

# Secrets Manager ARN
DB_SECRET_ARN=arn:aws:secretsmanager:ap-northeast-2:873240210647:secret:/bt-portal/prod/db-CR1Hcz
JWT_SECRET_ARN=arn:aws:secretsmanager:ap-northeast-2:873240210647:secret:/bt-portal/prod/jwt-mPOCpx
TOSS_SECRET_ARN=arn:aws:secretsmanager:ap-northeast-2:873240210647:secret:/bt-portal/prod/toss-UNCi2x

# S3 버킷 설정
S3_UPLOADS_BUCKET=bt-portal-prod-uploads
S3_FRONTEND_BUCKET=bt-portal-prod-frontend
S3_ADMIN_BUCKET=bt-portal-prod-admin

# CORS 설정
CORS_ALLOWED_ORIGINS=*

# CloudFront URL
FRONTEND_URL=https://d1b1usg810fogj.cloudfront.net
ADMIN_URL=https://d1idoail4yv1n8.cloudfront.net
API_URL=https://dxiy3sxobi0f3.cloudfront.net
CDN_URL=https://d26b61xscm73kk.cloudfront.net
EOF

chmod 600 /home/ec2-user/.env
```

### 5. Docker Compose 파일 예시

`docker-compose.yml` 파일 예시:

```yaml
version: '3.8'

services:
  backend:
    image: your-backend-image:latest
    container_name: bt-portal-backend
    ports:
      - "18082:18082"
    env_file:
      - .env
    environment:
      - SPRING_PROFILES_ACTIVE=prod
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18082/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "awslogs"
      options:
        awslogs-group: "/bt-portal/prod/backend"
        awslogs-region: "ap-northeast-2"
        awslogs-stream-prefix: "backend"
```

### 6. Docker 이미지 빌드 및 배포

#### 로컬에서 이미지 빌드
```bash
docker build -t bt-portal-backend:latest .
```

#### ECR에 푸시 (선택사항)
```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-2.amazonaws.com

# 이미지 태그
docker tag bt-portal-backend:latest <account-id>.dkr.ecr.ap-northeast-2.amazonaws.com/bt-portal-backend:latest

# 푸시
docker push <account-id>.dkr.ecr.ap-northeast-2.amazonaws.com/bt-portal-backend:latest
```

#### EC2에서 이미지 실행
```bash
# Docker Compose 사용
docker-compose up -d

# 또는 직접 실행
docker run -d \
  --name bt-portal-backend \
  --env-file .env \
  -p 18082:18082 \
  --restart unless-stopped \
  your-backend-image:latest
```

### 7. 애플리케이션 로그 확인

```bash
# Docker 로그 확인
docker logs -f bt-portal-backend

# CloudWatch Logs 확인
aws logs tail /bt-portal/prod/backend --follow --region ap-northeast-2
```

### 8. 헬스 체크

```bash
# 로컬 헬스 체크
curl http://localhost:18082/actuator/health

# CloudFront를 통한 헬스 체크
curl https://dxiy3sxobi0f3.cloudfront.net/actuator/health
```

---

## 🔧 애플리케이션 설정 예시

### Spring Boot `application-prod.yml` 예시

```yaml
spring:
  datasource:
    url: jdbc:postgresql://bt-portal-prod-postgres.cb8q6s28g4gg.ap-northeast-2.rds.amazonaws.com:5432/btportal
    username: postgres
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false

server:
  port: ${SERVER_PORT:18082}

aws:
  region: ${AWS_REGION:ap-northeast-2}
  secrets:
    db: ${DB_SECRET_ARN}
    jwt: ${JWT_SECRET_ARN}
    toss: ${TOSS_SECRET_ARN}
  s3:
    uploads-bucket: ${S3_UPLOADS_BUCKET}
    frontend-bucket: ${S3_FRONTEND_BUCKET}
    admin-bucket: ${S3_ADMIN_BUCKET}

cors:
  allowed-origins: ${CORS_ALLOWED_ORIGINS:*}

cloudfront:
  frontend-url: ${FRONTEND_URL}
  admin-url: ${ADMIN_URL}
  api-url: ${API_URL}
  cdn-url: ${CDN_URL}
```

---

## 📝 주의사항

1. **비밀번호 보안**
   - `terraform.tfvars` 파일의 `db_password`는 실제 비밀번호로 변경하세요
   - `.env` 파일은 Git에 커밋하지 마세요
   - Secrets Manager를 사용하여 민감한 정보를 관리하세요

2. **포트 설정**
   - 애플리케이션은 반드시 포트 `18082`에서 실행되어야 합니다
   - CloudFront가 이 포트로 요청을 전달합니다

3. **CORS 설정**
   - 현재는 모든 origin(`*`)을 허용합니다
   - 프로덕션 환경에서는 특정 도메인만 허용하도록 변경하세요

4. **데이터베이스 연결**
   - RDS는 VPC 내부에서만 접근 가능합니다
   - EC2 인스턴스는 자동으로 RDS에 접근할 수 있습니다

5. **로그 관리**
   - CloudWatch Logs에 로그가 자동으로 전송됩니다
   - 로그 그룹: `/bt-portal/prod/backend`

---

## 🚀 배포 체크리스트

- [ ] EC2 인스턴스 접속 확인
- [ ] Docker 설치 확인
- [ ] 환경 변수 설정 완료
- [ ] 데이터베이스 연결 테스트
- [ ] Secrets Manager 접근 권한 확인
- [ ] S3 버킷 접근 권한 확인
- [ ] Docker 이미지 빌드 및 배포
- [ ] 애플리케이션 헬스 체크 통과
- [ ] CloudFront를 통한 API 접근 확인
- [ ] 로그 확인

---

## 📞 문제 해결

### 데이터베이스 연결 실패
```bash
# RDS 보안 그룹 확인
aws ec2 describe-security-groups --group-ids sg-008fb3b2b30f8239f --region ap-northeast-2

# 네트워크 연결 테스트
telnet bt-portal-prod-postgres.cb8q6s28g4gg.ap-northeast-2.rds.amazonaws.com 5432
```

### Secrets Manager 접근 실패
```bash
# IAM 역할 확인
aws sts get-caller-identity

# Secrets Manager 권한 테스트
aws secretsmanager get-secret-value --secret-id /bt-portal/prod/db --region ap-northeast-2
```

### S3 접근 실패
```bash
# S3 버킷 목록 확인
aws s3 ls s3://bt-portal-prod-uploads --region ap-northeast-2
```

---

## 📚 참고 자료

- [AWS Session Manager 문서](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [AWS Secrets Manager 문서](https://docs.aws.amazon.com/secretsmanager/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
- [Spring Boot 배포 가이드](https://spring.io/guides/gs/spring-boot-for-aws/)


