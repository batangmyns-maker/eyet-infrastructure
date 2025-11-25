# CloudFront 주소 분기 기능 가이드

## 📋 개요

CloudFront는 여러 방법으로 주소/경로 기반 분기를 지원합니다.

---

## 🔀 방법 1: Cache Behaviors (경로 패턴 기반)

### 특징
- 하나의 CloudFront Distribution에서 경로 패턴으로 분기
- 예: `/api/*` → 백엔드, `/admin/*` → 관리자

### 예시 구조
```
example.com/          → S3 프론트엔드 (default)
example.com/admin/*   → S3 관리자
example.com/api/*     → EC2 백엔드
example.com/uploads/* → S3 업로드 파일
```

### 구현 방법
```hcl
# Terraform 예시
resource "aws_cloudfront_distribution" "unified" {
  # Origin 정의
  origin {
    domain_name = var.frontend_bucket
    origin_id   = "S3-Frontend"
  }
  
  origin {
    domain_name = var.ec2_dns
    origin_id   = "EC2-Backend"
  }

  # 기본 동작
  default_cache_behavior {
    target_origin_id = "S3-Frontend"
    # ...
  }

  # API 경로 분기
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "EC2-Backend"
    # API는 캐싱 안 함
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }
}
```

### 장단점
✅ 장점:
- 설정이 비교적 간단
- Terraform으로 관리 가능
- 경로 기반 명확한 분리

❌ 단점:
- 하나의 커스텀 도메인만 사용 가능
- 경로 패턴이 고정됨

---

## 🔀 방법 2: Lambda@Edge / CloudFront Functions (Host 헤더 기반)

### 특징
- Host 헤더를 보고 동적으로 분기
- 예: `www.example.com` → 프론트엔드, `api.example.com` → 백엔드

### 예시 구조
```
www.example.com  → S3 프론트엔드
admin.example.com → S3 관리자
api.example.com   → EC2 백엔드
cdn.example.com   → S3 업로드 파일
```

### 구현 방법
```javascript
// CloudFront Functions 예시
function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;

    // Host 헤더에 따라 origin 변경
    if (host.startsWith('api.')) {
        request.origin.custom.domainName = 'api-backend.example.com';
        request.origin.custom.path = '';
    } else if (host.startsWith('www.')) {
        request.origin.s3.domainName = 'frontend-bucket.s3.amazonaws.com';
        request.origin.s3.path = '';
    }

    return request;
}
```

### 장단점
✅ 장점:
- 여러 서브도메인 사용 가능
- 동적 분기 가능
- 더 유연한 라우팅

❌ 단점:
- Lambda@Edge는 비용 발생 (요청당)
- 코드 관리 필요
- 디버깅이 복잡할 수 있음

---

## 🔀 방법 3: 별도 Distribution (현재 구조)

### 특징
- 각 서비스별로 독립적인 CloudFront Distribution
- 가장 단순하고 명확한 구조

### 예시 구조
```
프론트엔드: d1b1usg810fogj.cloudfront.net → S3
관리자:     d1idoail4yv1n8.cloudfront.net → S3
API:        dxiy3sxobi0f3.cloudfront.net  → EC2
CDN:        d26b61xscm73kk.cloudfront.net → S3
```

### 장단점
✅ 장점:
- 구조가 명확함
- 각 서비스 독립 관리
- 문제 발생 시 영향 범위 제한
- 커스텀 도메인을 각각 다르게 설정 가능

❌ 단점:
- Distribution이 많아짐 (관리 복잡도 증가)
- 비용은 동일 (Distribution 개수와 무관)

---

## 💡 권장사항

### 현재 구조 유지 (별도 Distribution)
**권장하는 경우:**
- ✅ 이미 잘 작동하고 있음
- ✅ 커스텀 도메인을 각각 다르게 설정하고 싶은 경우
- ✅ 각 서비스의 캐시 정책이 완전히 다른 경우
- ✅ 관리 복잡도를 감수할 수 있는 경우

**예시:**
```
www.yourdomain.com  → 프론트엔드 Distribution
admin.yourdomain.com → 관리자 Distribution  
api.yourdomain.com   → API Distribution
cdn.yourdomain.com   → CDN Distribution
```

### 통합 Distribution (경로 기반)
**권장하는 경우:**
- ✅ 하나의 도메인으로 통합하고 싶은 경우
- ✅ 경로 기반 분기로 충분한 경우
- ✅ Distribution 개수를 줄이고 싶은 경우

**예시:**
```
yourdomain.com/        → 프론트엔드
yourdomain.com/admin/* → 관리자
yourdomain.com/api/*   → API
yourdomain.com/uploads/* → 업로드 파일
```

---

## 📊 비교표

| 항목 | 별도 Distribution | 통합 Distribution (경로) | Lambda@Edge |
|------|------------------|------------------------|-------------|
| **설정 복잡도** | 낮음 | 중간 | 높음 |
| **유연성** | 높음 | 중간 | 매우 높음 |
| **비용** | 동일 | 동일 | 추가 비용 |
| **커스텀 도메인** | 여러 개 가능 | 하나만 가능 | 여러 개 가능 |
| **관리** | 복잡 (4개) | 단순 (1개) | 중간 (1개 + 코드) |
| **디버깅** | 쉬움 | 쉬움 | 어려움 |

---

## 🔧 현재 프로젝트 적용

현재 프로젝트는 **별도 Distribution 구조**를 사용하고 있습니다.

### 변경 시 고려사항

1. **통합으로 변경하려면:**
   - `terraform/modules/cloudfront/main.tf` 수정
   - 기존 Distribution 삭제 및 재생성
   - 다운타임 발생 가능

2. **현재 구조 유지 시:**
   - 변경 불필요
   - 이미 잘 작동 중
   - 커스텀 도메인 설정 시 각각 다른 도메인 사용 가능

---

## 📚 참고 자료

- [AWS CloudFront Cache Behaviors](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesCacheBehavior)
- [CloudFront Functions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html)
- [Lambda@Edge](https://docs.aws.amazon.com/lambda/latest/dg/lambda-edge.html)
