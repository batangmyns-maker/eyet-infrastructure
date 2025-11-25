#!/bin/bash
# 백엔드 배포 스크립트

set -e

ENVIRONMENT="prod"
BACKEND_DIR="../../bt-portal-backend"

echo "========================================="
echo "백엔드 배포 시작"
echo "  환경: $ENVIRONMENT"
echo "========================================="

# Terraform output에서 EC2 IP 가져오기
cd "../terraform/environments/prod"
EC2_IP=$(terraform output -raw ec2_public_ip)

if [ -z "$EC2_IP" ]; then
    echo "❌ EC2 IP를 가져올 수 없습니다."
    echo "   terraform apply를 먼저 실행해주세요."
    exit 1
fi

echo "✅ EC2 IP: $EC2_IP"

# 백엔드 디렉터리로 이동
cd "$BACKEND_DIR"

# Git 최신 코드 가져오기
echo ""
echo "📥 Git 최신 코드 가져오기..."
git pull origin main

# Gradle 빌드
echo ""
echo "🔨 Gradle 빌드 중..."
./gradlew clean build -x test

# Docker 이미지 빌드
echo ""
echo "🐳 Docker 이미지 빌드 중..."
docker build -t bt-portal-backend:latest .

# Docker 이미지를 tar로 저장
echo ""
echo "📦 Docker 이미지 저장 중..."
docker save bt-portal-backend:latest | gzip > bt-portal-backend.tar.gz

# EC2로 이미지 전송
echo ""
echo "☁️  EC2로 이미지 전송 중..."
scp -i ~/.ssh/bt-portal-${ENVIRONMENT}-key.pem \
    bt-portal-backend.tar.gz \
    ec2-user@${EC2_IP}:/tmp/

# EC2에서 배포 실행
echo ""
echo "🚀 EC2에서 배포 실행 중..."
ssh -i ~/.ssh/bt-portal-${ENVIRONMENT}-key.pem ec2-user@${EC2_IP} << 'ENDSSH'
# Docker 이미지 로드
echo "Docker 이미지 로드 중..."
docker load < /tmp/bt-portal-backend.tar.gz

# 기존 컨테이너 중지 및 삭제
echo "기존 컨테이너 중지 중..."
cd /app
docker-compose down || true

# 🔐 참고: Spring Boot가 시작하면서 Secrets Manager에서 자동으로 조회합니다.
# DB 비밀번호, JWT Secret, Toss Secret은 별도로 설정할 필요 없습니다.

# 새 컨테이너 시작
echo "새 컨테이너 시작 중..."
echo "💡 Spring Boot가 Secrets Manager에서 설정을 조회합니다..."
docker-compose up -d

# 헬스체크
echo "헬스체크 대기 중..."
sleep 10

for i in {1..30}; do
    if curl -f http://localhost:18082/actuator/health > /dev/null 2>&1; then
        echo "✅ 애플리케이션이 정상적으로 시작되었습니다."
        echo "   Secrets Manager 연동 성공!"
        exit 0
    fi
    echo "헬스체크 대기 중... ($i/30)"
    sleep 2
done

echo "❌ 헬스체크 실패. 로그를 확인해주세요."
echo "   Secrets Manager 권한을 확인하세요."
docker-compose logs --tail=50
exit 1
ENDSSH

# 임시 파일 삭제
rm -f bt-portal-backend.tar.gz

echo ""
echo "========================================="
echo "✅ 백엔드 배포 완료!"
echo "========================================="
echo ""
echo "API URL: https://api.example.com"
echo ""
echo "로그 확인:"
echo "  ssh -i ~/.ssh/bt-portal-prod-key.pem ec2-user@${EC2_IP}"
echo "  cd /app && docker-compose logs -f"


