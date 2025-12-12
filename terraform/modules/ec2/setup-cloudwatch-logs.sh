#!/bin/bash
# 기존 EC2 인스턴스에 CloudWatch Logs Agent 설정을 적용하는 스크립트
# 사용법: 이 스크립트를 EC2 인스턴스에 복사한 후 실행
# 예: scp setup-cloudwatch-logs.sh ec2-user@your-instance:/tmp/
#     ssh ec2-user@your-instance "sudo bash /tmp/setup-cloudwatch-logs.sh"

set -e

echo "========================================="
echo "CloudWatch Logs Agent 설정 시작"
echo "========================================="

# 환경 변수 설정 (실제 환경에 맞게 수정 필요)
ENVIRONMENT="${ENVIRONMENT:-prod}"  # 환경 변수로 설정하거나 직접 수정

# CloudWatch Logs Agent 설치 확인
if ! command -v amazon-cloudwatch-agent-ctl &> /dev/null; then
    echo "CloudWatch Logs Agent 설치 중..."
    sudo yum install -y amazon-cloudwatch-agent
else
    echo "CloudWatch Logs Agent가 이미 설치되어 있습니다."
fi

# 로그 디렉토리 권한 설정
echo "로그 디렉토리 권한 설정 중..."
sudo mkdir -p /home/ssm-user/eyet-backend/logs
sudo chown -R ssm-user:ssm-user /home/ssm-user/eyet-backend
sudo chmod -R 755 /home/ssm-user/eyet-backend/logs || true

# CloudWatch Logs Agent 설정 파일 생성
echo "CloudWatch Logs Agent 설정 파일 생성 중..."
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${ENVIRONMENT}/application.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "application-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${ENVIRONMENT}/access.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "access-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${ENVIRONMENT}/error.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "error-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${ENVIRONMENT}/sql.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "sql-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${ENVIRONMENT}/workflow-scheduler.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "workflow-scheduler-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${ENVIRONMENT}/license-subscription-scheduler.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "license-subscription-scheduler-{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "nginx-access-{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${ENVIRONMENT}",
            "log_stream_name": "nginx-error-{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# CloudWatch Logs Agent 재시작
echo "CloudWatch Logs Agent 설정 적용 중..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Agent 상태 확인
echo "========================================="
echo "CloudWatch Logs Agent 상태 확인"
echo "========================================="
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status

echo "========================================="
echo "설정 완료!"
echo "========================================="
echo "CloudWatch Logs 콘솔에서 다음 Log Group을 확인하세요:"
echo "/aws/ec2/bt-portal-backend/${ENVIRONMENT}"
echo ""
echo "로그 확인 방법:"
echo "  AWS CLI: aws logs tail /aws/ec2/bt-portal-backend/${ENVIRONMENT} --follow"
echo "  또는 AWS Console → CloudWatch → Logs → Log groups"
