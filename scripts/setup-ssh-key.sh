#!/bin/bash
# AWS EC2 SSH Key Pair 생성 스크립트

set -e

ENVIRONMENT="prod"
KEY_NAME="bt-portal-prod-key"
REGION="ap-northeast-2"

echo "========================================="
echo "SSH Key Pair 생성"
echo "  Key Name: $KEY_NAME"
echo "========================================="

# 기존 키가 있는지 확인
if [ -f ~/.ssh/${KEY_NAME}.pem ]; then
    echo "⚠️  기존 키 파일이 존재합니다: ~/.ssh/${KEY_NAME}.pem"
    read -p "덮어쓰시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 1
    fi
    rm -f ~/.ssh/${KEY_NAME}.pem
fi

# AWS에서 키 페어 생성
echo ""
echo "AWS에서 키 페어 생성 중..."

# 기존 키 페어 삭제 (있다면)
aws ec2 delete-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    2>/dev/null || true

# 새 키 페어 생성 및 저장
aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/${KEY_NAME}.pem

# 권한 설정
chmod 400 ~/.ssh/${KEY_NAME}.pem

echo "✅ SSH 키 생성 완료: ~/.ssh/${KEY_NAME}.pem"
echo ""
echo "========================================="
echo "다음 단계:"
echo "========================================="
echo "1. terraform.tfvars 파일에 다음 설정 추가:"
echo "   ec2_key_name = \"$KEY_NAME\""
echo ""
echo "2. SSH 접속 테스트 (terraform apply 후):"
echo "   ssh -i ~/.ssh/${KEY_NAME}.pem ec2-user@<EC2_IP>"


