# 프론트엔드 정적 파일 배포 가이드

## 📋 개요

이 문서는 프론트엔드 정적 파일을 S3 버킷에 업로드하고 CloudFront를 통해 배포하는 방법을 설명합니다.

---

## 🪣 S3 버킷 정보

### 버킷 목록
- **프론트엔드**: `bt-portal-prod-frontend`
- **관리자**: `bt-portal-prod-admin`
- **업로드 파일**: `bt-portal-prod-uploads`

### 버킷 설정
- **리전**: `ap-northeast-2` (서울)
- **버전 관리**: 활성화됨
- **암호화**: AES-256 (SSE-S3)
- **정적 웹사이트 호스팅**: 활성화됨

---

## 🌐 CloudFront URL

### 배포된 서비스 URL
- **프론트엔드**: https://d1b1usg810fogj.cloudfront.net
- **관리자**: https://d1idoail4yv1n8.cloudfront.net
- **CDN (업로드 파일)**: https://d26b61xscm73kk.cloudfront.net

---

## 🚀 배포 방법

### 방법 1: AWS CLI를 사용한 배포 (권장)

#### 1. AWS CLI 설치 및 설정
```bash
# AWS CLI 설치 확인
aws --version

# AWS 자격증명 설정 (이미 설정되어 있다면 생략)
aws configure
# AWS Access Key ID 입력
# AWS Secret Access Key 입력
# Default region name: ap-northeast-2
# Default output format: json
```

#### 2. 빌드된 정적 파일 준비
```bash
# React/Vue/Next.js 등 프론트엔드 프로젝트 빌드
npm run build
# 또는
yarn build

# 빌드 결과물 확인 (일반적으로 dist, build, out 등)
ls -la dist/
```

#### 3. S3 버킷에 파일 업로드

##### 프론트엔드 배포
```bash
# 빌드된 파일을 S3에 동기화 (기존 파일 삭제 후 업로드)
aws s3 sync dist/ s3://bt-portal-prod-frontend/ \
  --region ap-northeast-2 \
  --delete \
  --cache-control "public, max-age=31536000, immutable"

# 또는 특정 파일만 업로드
aws s3 cp dist/index.html s3://bt-portal-prod-frontend/index.html \
  --region ap-northeast-2 \
  --content-type "text/html" \
  --cache-control "public, max-age=0, must-revalidate"

# JavaScript/CSS 파일은 캐싱 설정
aws s3 cp dist/assets/ s3://bt-portal-prod-frontend/assets/ \
  --region ap-northeast-2 \
  --recursive \
  --cache-control "public, max-age=31536000, immutable"
```

##### 관리자 페이지 배포
```bash
# 관리자 페이지 빌드 후 배포
aws s3 sync admin-dist/ s3://bt-portal-prod-admin/ \
  --region ap-northeast-2 \
  --delete \
  --cache-control "public, max-age=31536000, immutable"
```

#### 4. CloudFront 캐시 무효화 (선택사항)

새로운 파일이 배포되었지만 CloudFront 캐시가 남아있을 수 있습니다. 캐시를 무효화하여 즉시 반영할 수 있습니다.

```bash
# 프론트엔드 CloudFront 캐시 무효화
aws cloudfront create-invalidation \
  --distribution-id E2NPK9IXTPVNZ1 \
  --paths "/*" \
  --region ap-northeast-2

# 관리자 CloudFront 캐시 무효화
aws cloudfront create-invalidation \
  --distribution-id EHV5LVBJ05YTB \
  --paths "/*" \
  --region ap-northeast-2
```

---

### 방법 2: AWS Console을 사용한 배포

#### 1. S3 버킷 접근
1. AWS Console → S3 → 버킷 선택 (`bt-portal-prod-frontend` 또는 `bt-portal-prod-admin`)
2. "업로드" 버튼 클릭

#### 2. 파일 업로드
1. 빌드된 파일들을 선택하여 업로드
2. "속성" 탭에서 다음 설정:
   - **콘텐츠 유형**: 
     - HTML: `text/html`
     - CSS: `text/css`
     - JavaScript: `application/javascript`
     - 이미지: `image/png`, `image/jpeg` 등
   - **캐시 제어**: 
     - HTML: `public, max-age=0, must-revalidate`
     - 정적 자산: `public, max-age=31536000, immutable`

#### 3. CloudFront 캐시 무효화
1. AWS Console → CloudFront → 배포 선택
2. "무효화" 탭 → "무효화 생성"
3. 객체 경로: `/*` 입력
4. "무효화 생성" 클릭

---

### 방법 3: CI/CD 파이프라인 사용 (GitHub Actions 예시)

#### GitHub Actions 워크플로우 예시

`.github/workflows/deploy-frontend.yml`:

```yaml
name: Deploy Frontend to S3 and CloudFront

on:
  push:
    branches:
      - main
    paths:
      - 'frontend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci
      
      - name: Build
        working-directory: ./frontend
        run: npm run build
        env:
          REACT_APP_API_URL: https://dxiy3sxobi0f3.cloudfront.net
          REACT_APP_CDN_URL: https://d26b61xscm73kk.cloudfront.net
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-2
      
      - name: Deploy to S3
        working-directory: ./frontend
        run: |
          aws s3 sync build/ s3://bt-portal-prod-frontend/ \
            --region ap-northeast-2 \
            --delete \
            --cache-control "public, max-age=31536000, immutable"
      
      - name: Invalidate CloudFront cache
        run: |
          aws cloudfront create-invalidation \
            --distribution-id E2NPK9IXTPVNZ1 \
            --paths "/*" \
            --region ap-northeast-2
```

---

## 📁 파일 구조 및 권장사항

### 권장 디렉토리 구조
```
frontend/
├── build/              # 빌드 결과물
│   ├── index.html
│   ├── assets/
│   │   ├── main.[hash].js
│   │   ├── main.[hash].css
│   │   └── images/
│   └── static/
└── ...
```

### S3 버킷 구조
```
s3://bt-portal-prod-frontend/
├── index.html
├── assets/
│   ├── main.abc123.js
│   ├── main.def456.css
│   └── images/
└── static/
```

---

## ⚙️ 환경 변수 설정

### 빌드 시 필요한 환경 변수

프론트엔드 빌드 시 다음 환경 변수를 설정해야 합니다:

```bash
# .env.production 파일 예시
REACT_APP_API_URL=https://dxiy3sxobi0f3.cloudfront.net
REACT_APP_ADMIN_URL=https://d1idoail4yv1n8.cloudfront.net
REACT_APP_CDN_URL=https://d26b61xscm73kk.cloudfront.net
REACT_APP_ENV=production
```

### React 예시
```bash
# 빌드 시 환경 변수 주입
REACT_APP_API_URL=https://dxiy3sxobi0f3.cloudfront.net npm run build
```

### Vue 예시
```bash
# .env.production 파일 생성
VUE_APP_API_URL=https://dxiy3sxobi0f3.cloudfront.net
VUE_APP_CDN_URL=https://d26b61xscm73kk.cloudfront.net

# 빌드
npm run build
```

### Next.js 예시
```javascript
// next.config.js
module.exports = {
  env: {
    NEXT_PUBLIC_API_URL: 'https://dxiy3sxobi0f3.cloudfront.net',
    NEXT_PUBLIC_CDN_URL: 'https://d26b61xscm73kk.cloudfront.net',
  },
  output: 'export', // 정적 내보내기
}
```

---

## 🔧 캐싱 전략

### 파일별 캐싱 설정

#### HTML 파일
- **캐시 제어**: `public, max-age=0, must-revalidate`
- **이유**: 항상 최신 버전을 제공해야 함

```bash
aws s3 cp dist/index.html s3://bt-portal-prod-frontend/index.html \
  --content-type "text/html" \
  --cache-control "public, max-age=0, must-revalidate"
```

#### 정적 자산 (JS, CSS, 이미지)
- **캐시 제어**: `public, max-age=31536000, immutable`
- **이유**: 파일명에 해시가 포함되어 있어 변경 시 자동으로 새 파일로 교체됨

```bash
aws s3 sync dist/assets/ s3://bt-portal-prod-frontend/assets/ \
  --cache-control "public, max-age=31536000, immutable"
```

#### API 응답
- CloudFront에서 API는 캐싱하지 않도록 설정됨 (TTL: 0)

---

## 🔄 배포 스크립트 예시

### 배포 스크립트 (deploy.sh)

```bash
#!/bin/bash

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 프론트엔드 배포 시작...${NC}"

# 1. 빌드
echo -e "${YELLOW}📦 빌드 중...${NC}"
npm run build

# 2. S3 업로드
echo -e "${YELLOW}📤 S3에 업로드 중...${NC}"
aws s3 sync build/ s3://bt-portal-prod-frontend/ \
  --region ap-northeast-2 \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html"

# HTML 파일은 별도 업로드 (캐시 없음)
aws s3 cp build/index.html s3://bt-portal-prod-frontend/index.html \
  --region ap-northeast-2 \
  --content-type "text/html" \
  --cache-control "public, max-age=0, must-revalidate"

# 3. CloudFront 캐시 무효화
echo -e "${YELLOW}🔄 CloudFront 캐시 무효화 중...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id E2NPK9IXTPVNZ1 \
  --paths "/*" \
  --region ap-northeast-2 \
  --query 'Invalidation.Id' \
  --output text)

echo -e "${GREEN}✅ 배포 완료!${NC}"
echo -e "${GREEN}캐시 무효화 ID: ${INVALIDATION_ID}${NC}"
echo -e "${GREEN}URL: https://d1b1usg810fogj.cloudfront.net${NC}"
```

### 사용 방법
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 📝 배포 체크리스트

### 배포 전 확인사항
- [ ] 빌드가 성공적으로 완료되었는지 확인
- [ ] 환경 변수가 올바르게 설정되었는지 확인
- [ ] API URL이 올바른지 확인
- [ ] 빌드 결과물이 올바른지 확인

### 배포 중 확인사항
- [ ] S3 업로드가 성공했는지 확인
- [ ] 파일 권한이 올바른지 확인
- [ ] Content-Type이 올바른지 확인

### 배포 후 확인사항
- [ ] CloudFront 캐시 무효화가 완료되었는지 확인
- [ ] 웹사이트가 정상적으로 로드되는지 확인
- [ ] API 호출이 정상적으로 작동하는지 확인
- [ ] 이미지 및 정적 자산이 정상적으로 로드되는지 확인

---

## 🔍 문제 해결

### 문제 1: 파일이 업데이트되지 않음

**원인**: CloudFront 캐시가 남아있음

**해결 방법**:
```bash
# CloudFront 캐시 무효화
aws cloudfront create-invalidation \
  --distribution-id E2NPK9IXTPVNZ1 \
  --paths "/*" \
  --region ap-northeast-2
```

### 문제 2: 403 Forbidden 오류

**원인**: S3 버킷 정책 또는 CloudFront OAC 설정 문제

**해결 방법**:
1. S3 버킷 정책 확인
2. CloudFront Origin Access Control (OAC) 설정 확인
3. Terraform으로 재배포

### 문제 3: CORS 오류

**원인**: CORS 설정이 올바르지 않음

**해결 방법**:
- S3 버킷 CORS 설정 확인
- CloudFront 헤더 설정 확인

### 문제 4: 빌드 파일이 너무 큼

**원인**: 최적화가 제대로 되지 않음

**해결 방법**:
```bash
# 빌드 최적화 확인
npm run build -- --analyze

# 압축 확인
gzip -k dist/assets/*.js
```

---

## 🔐 보안 설정

### S3 버킷 정책
- CloudFront OAC를 통해서만 접근 가능
- 직접 S3 URL 접근 불가

### CloudFront 보안
- HTTPS 강제 (HTTP → HTTPS 리다이렉트)
- TLS 1.2 이상 사용

---

## 📊 모니터링

### CloudFront 메트릭 확인
```bash
# CloudWatch 메트릭 확인
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E2NPK9IXTPVNZ1 \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum \
  --region us-east-1
```

### S3 접근 로그 확인
- S3 버킷 접근 로그 활성화 (선택사항)
- CloudFront 액세스 로그 활성화 (선택사항)

---

## 🚀 빠른 배포 명령어

### 프론트엔드 배포 (한 줄)
```bash
npm run build && \
aws s3 sync build/ s3://bt-portal-prod-frontend/ \
  --region ap-northeast-2 \
  --delete \
  --cache-control "public, max-age=31536000, immutable" && \
aws s3 cp build/index.html s3://bt-portal-prod-frontend/index.html \
  --content-type "text/html" \
  --cache-control "public, max-age=0, must-revalidate" && \
aws cloudfront create-invalidation \
  --distribution-id E2NPK9IXTPVNZ1 \
  --paths "/*" \
  --region ap-northeast-2
```

### 관리자 페이지 배포 (한 줄)
```bash
npm run build:admin && \
aws s3 sync admin-build/ s3://bt-portal-prod-admin/ \
  --region ap-northeast-2 \
  --delete \
  --cache-control "public, max-age=31536000, immutable" && \
aws s3 cp admin-build/index.html s3://bt-portal-prod-admin/index.html \
  --content-type "text/html" \
  --cache-control "public, max-age=0, must-revalidate" && \
aws cloudfront create-invalidation \
  --distribution-id EHV5LVBJ05YTB \
  --paths "/*" \
  --region ap-northeast-2
```

---

## 📚 참고 자료

- [AWS S3 문서](https://docs.aws.amazon.com/s3/)
- [AWS CloudFront 문서](https://docs.aws.amazon.com/cloudfront/)
- [AWS CLI S3 명령어](https://docs.aws.amazon.com/cli/latest/reference/s3/)
- [CloudFront 캐시 무효화](https://docs.aws.amazon.com/cloudfront/latest/DeveloperGuide/Invalidation.html)

---

## 📞 지원

배포 중 문제가 발생하면 다음을 확인하세요:
1. AWS 자격증명이 올바른지 확인
2. S3 버킷 권한 확인
3. CloudFront 배포 상태 확인
4. Terraform 상태 확인


