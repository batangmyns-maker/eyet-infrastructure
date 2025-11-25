# 프론트엔드 환경 변수 설정 가이드

## 📋 Vite 환경 변수 설정

### 프로덕션 환경 (.env.prod 또는 .env.production)

```bash
# API Base URL
VITE_API_BASE_URL="https://dxiy3sxobi0f3.cloudfront.net"

# Toss Payments 클라이언트 키
# ⚠️ 프로덕션 환경에서는 live_ck_로 시작하는 키를 사용해야 합니다!
VITE_TOSS_CLIENT_KEY="test_ck_yL0qZ4G1VOjR2D75MpqR3oWb2MQY"

# 선택사항: CDN URL (이미지/파일 업로드)
VITE_CDN_URL="https://d26b61xscm73kk.cloudfront.net"

# 선택사항: 관리자 URL
VITE_ADMIN_URL="https://d1idoail4yv1n8.cloudfront.net"

# 환경 변수
VITE_ENV="production"
```

---

## 🔍 현재 설정 확인

### ✅ 올바른 설정
```bash
# API URL - CloudFront Distribution 사용
VITE_API_BASE_URL="https://dxiy3sxobi0f3.cloudfront.net"
```

### ⚠️ 주의사항
```bash
# 주석 처리된 커스텀 도메인
#VITE_API_BASE_URL="http://eyet.kr/api"
```

이 커스텀 도메인을 사용하려면:
1. Terraform에서 `use_custom_domain = true` 설정
2. Route53 DNS 설정
3. ACM 인증서 발급 및 검증
4. 그 후 `api.eyet.kr` 형식으로 변경

---

## 🔑 Toss Payments 키 확인

### 현재 설정
```bash
VITE_TOSS_CLIENT_KEY="test_ck_yL0qZ4G1VOjR2D75MpqR3oWb2MQY"
```

### 중요!
- **`test_ck_`**: 테스트 환경 키 (현재 사용 중)
- **`live_ck_`**: 실제 결제 처리용 프로덕션 키

### 프로덕션 배포 시
```bash
# 프로덕션에서는 반드시 live 키 사용!
VITE_TOSS_CLIENT_KEY="live_ck_..."
```

⚠️ **주의**: 테스트 키로는 실제 결제가 되지 않습니다!

---

## 📝 완전한 예시 파일

### `.env.production` (프로덕션)
```bash
# ==========================================
# API 설정
# ==========================================
VITE_API_BASE_URL="https://dxiy3sxobi0f3.cloudfront.net"

# 커스텀 도메인 사용 시 (Terraform 설정 후)
# VITE_API_BASE_URL="https://api.eyet.kr"

# ==========================================
# Toss Payments
# ==========================================
# 테스트 키
VITE_TOSS_CLIENT_KEY="test_ck_yL0qZ4G1VOjR2D75MpqR3oWb2MQY"

# 프로덕션 키 (실제 배포 시)
# VITE_TOSS_CLIENT_KEY="live_ck_..."

# ==========================================
# 기타 URL
# ==========================================
VITE_CDN_URL="https://d26b61xscm73kk.cloudfront.net"
VITE_FRONTEND_URL="https://d1b1usg810fogj.cloudfront.net"
VITE_ADMIN_URL="https://d1idoail4yv1n8.cloudfront.net"

# ==========================================
# 환경 설정
# ==========================================
VITE_ENV="production"
```

### `.env.development` (개발)
```bash
# 로컬 개발 서버
VITE_API_BASE_URL="http://localhost:18082"
VITE_TOSS_CLIENT_KEY="test_ck_yL0qZ4G1VOjR2D75MpqR3oWb2MQY"
VITE_ENV="development"
```

---

## 🚀 빌드 시 확인사항

### 1. 환경 변수 확인
```bash
# Vite는 VITE_ 접두사만 사용
# .env.production 파일이 제대로 읽히는지 확인
npm run build
```

### 2. 빌드된 코드에서 확인
빌드 후 `dist/index.html`이나 번들 파일에서 환경 변수가 제대로 주입되었는지 확인:

```javascript
// 예상되는 코드
const API_BASE_URL = "https://dxiy3sxobi0f3.cloudfront.net";
```

### 3. 빌드 시 직접 환경 변수 주입
```bash
# 환경 변수를 직접 지정하여 빌드
VITE_API_BASE_URL="https://dxiy3sxobi0f3.cloudfront.net" \
VITE_TOSS_CLIENT_KEY="test_ck_..." \
npm run build
```

---

## 📊 CloudFront URL 정리

### 현재 사용 중인 URL
- **프론트엔드**: `https://d1b1usg810fogj.cloudfront.net`
- **관리자**: `https://d1idoail4yv1n8.cloudfront.net`
- **API**: `https://dxiy3sxobi0f3.cloudfront.net` ⬅️ **현재 사용 중**
- **CDN**: `https://d26b61xscm73kk.cloudfront.net`

### 커스텀 도메인 사용 시 (향후)
- **프론트엔드**: `https://www.eyet.kr`
- **관리자**: `https://admin.eyet.kr`
- **API**: `https://api.eyet.kr`
- **CDN**: `https://cdn.eyet.kr`

---

## ✅ 최종 확인 체크리스트

- [x] API URL이 CloudFront Distribution URL로 설정됨
- [ ] Toss 클라이언트 키가 프로덕션 키로 변경되었는지 확인 (현재 테스트 키)
- [ ] 환경 변수가 빌드에 포함되는지 확인
- [ ] 커스텀 도메인 사용 여부 결정

---

## 🔗 관련 문서

- [프론트엔드 배포 가이드](./FRONTEND_DEPLOYMENT_GUIDE.md)
- [Terraform 출력값 확인](./terraform/environments/prod/outputs.tf)
