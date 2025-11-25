#!/bin/bash
# Terraform 백엔드 설정 스크립트
# S3 버킷과 DynamoDB 테이블 생성

set -e

# 변수 설정
BUCKET_NAME="bt-portal-terraform-state"
DYNAMODB_TABLE="bt-portal-terraform-locks"
REGION="ap-northeast-2"

echo "========================================="
echo "Terraform 백엔드 설정 시작"
echo "========================================="

# AWS CLI 설치 확인
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI가 설치되어 있지 않습니다."
    echo "   https://aws.amazon.com/cli/ 에서 설치해주세요."
    exit 1
fi

# AWS 자격 증명 확인
echo "AWS 계정 확인 중..."
aws sts get-caller-identity > /dev/null 2>&1 || {
    echo "❌ AWS 자격 증명이 설정되지 않았습니다."
    echo "   'aws configure' 명령으로 설정해주세요."
    exit 1
}

echo "✅ AWS 계정 확인 완료"

# S3 버킷 생성
echo ""
echo "S3 버킷 생성 중: $BUCKET_NAME"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    
    echo "✅ S3 버킷 생성 완료"
    
    # 버전 관리 활성화
    echo "S3 버전 관리 활성화 중..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    echo "✅ 버전 관리 활성화 완료"
    
    # 암호화 활성화
    echo "S3 암호화 활성화 중..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    echo "✅ 암호화 활성화 완료"
    
    # Public Access Block 활성화
    echo "Public Access Block 활성화 중..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    echo "✅ Public Access Block 활성화 완료"
else
    echo "ℹ️  S3 버킷이 이미 존재합니다: $BUCKET_NAME"
fi

# DynamoDB 테이블 생성
echo ""
echo "DynamoDB 테이블 생성 중: $DYNAMODB_TABLE"
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>&1 | grep -q 'ResourceNotFoundException'; then
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --tags Key=Project,Value=bt-portal Key=Purpose,Value=TerraformStateLock
    
    echo "✅ DynamoDB 테이블 생성 완료"
    
    # 테이블 생성 대기
    echo "테이블 활성화 대기 중..."
    aws dynamodb wait table-exists \
        --table-name "$DYNAMODB_TABLE" \
        --region "$REGION"
    
    echo "✅ 테이블 활성화 완료"
else
    echo "ℹ️  DynamoDB 테이블이 이미 존재합니다: $DYNAMODB_TABLE"
fi

echo ""
echo "========================================="
echo "✅ Terraform 백엔드 설정 완료!"
echo "========================================="
echo ""
echo "생성된 리소스:"
echo "  - S3 버킷: $BUCKET_NAME"
echo "  - DynamoDB 테이블: $DYNAMODB_TABLE"
echo ""
echo "이제 terraform init을 실행할 수 있습니다."


