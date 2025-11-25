#!/bin/bash
# 프론트엔드 배포 스크립트

set -e

# 인자 확인
if [ $# -lt 1 ]; then
    echo "사용법: $0 <frontend-type>"
    echo "  frontend-type: user (bt-portal-frontend) 또는 admin (bt-portal-admin-frontend)"
    exit 1
fi

ENVIRONMENT="prod"
FRONTEND_TYPE=$1

# 변수 설정
if [ "$FRONTEND_TYPE" = "user" ]; then
    FRONTEND_DIR="../../bt-portal-frontend"
    S3_BUCKET="bt-portal-prod-frontend"
    DISTRIBUTION_ID=$(cd ../terraform/environments/prod && terraform output -raw cloudfront_frontend_url | grep -oP 'https://\K[^/]+' | xargs aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[0]=='www.example.com'].Id" --output text)
elif [ "$FRONTEND_TYPE" = "admin" ]; then
    FRONTEND_DIR="../../bt-portal-admin-frontend"
    S3_BUCKET="bt-portal-prod-admin"
    DISTRIBUTION_ID=$(cd ../terraform/environments/prod && terraform output -raw cloudfront_admin_url | grep -oP 'https://\K[^/]+' | xargs aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[0]=='admin.example.com'].Id" --output text)
else
    echo "❌ 유효하지 않은 frontend-type: $FRONTEND_TYPE"
    echo "   user 또는 admin을 사용하세요."
    exit 1
fi

echo "========================================="
echo "프론트엔드 배포 시작"
echo "  타입: $FRONTEND_TYPE"
echo "  S3 버킷: $S3_BUCKET"
echo "========================================="

# 프론트엔드 디렉터리 확인
if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ 프론트엔드 디렉터리를 찾을 수 없습니다: $FRONTEND_DIR"
    exit 1
fi

cd "$FRONTEND_DIR"

# 의존성 설치
echo ""
echo "📦 의존성 설치 중..."
npm install

# 빌드
echo ""
echo "🔨 빌드 중..."
npm run build

# S3 업로드
echo ""
echo "☁️  S3에 업로드 중..."
aws s3 sync dist/ "s3://$S3_BUCKET" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "index.html"

# index.html은 캐시하지 않음
aws s3 cp dist/index.html "s3://$S3_BUCKET/index.html" \
    --cache-control "no-cache, no-store, must-revalidate"

echo "✅ S3 업로드 완료"

# CloudFront 캐시 무효화
echo ""
echo "🔄 CloudFront 캐시 무효화 중..."
if [ -n "$DISTRIBUTION_ID" ]; then
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    echo "✅ 캐시 무효화 요청 완료 (ID: $INVALIDATION_ID)"
    echo "   완료까지 5-10분 소요될 수 있습니다."
else
    echo "⚠️  CloudFront Distribution ID를 찾을 수 없습니다."
    echo "   Terraform output을 확인해주세요."
fi

echo ""
echo "========================================="
echo "✅ 프론트엔드 배포 완료!"
echo "========================================="


