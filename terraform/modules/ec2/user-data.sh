#!/bin/bash
set -e

# 로그 파일 설정
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "========================================="
echo "User Data Script Started at $(date)"
echo "========================================="

# 시스템 업데이트
echo "Updating system packages..."
sudo yum update -y

# Docker 설치
echo "Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Docker Compose 설치
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# CloudWatch Logs Agent 설치
echo "Installing CloudWatch Logs Agent..."
sudo yum install -y amazon-cloudwatch-agent

# Git 설치
echo "Installing Git..."
sudo yum install -y git

# 애플리케이션 디렉터리 생성
echo "Creating application directories..."
sudo mkdir -p /app
sudo mkdir -p /app/uploaded-files
sudo mkdir -p /app/logs/${environment}
sudo chown -R ec2-user:ec2-user /app

# 환경 변수 설정 (Spring Boot에서 사용)
# 주의: 민감한 정보는 Spring Boot가 직접 Secrets Manager에서 조회합니다.
# 여기서는 Spring Profile과 AWS 리전만 설정합니다.
echo "Creating environment configuration..."
cat <<EOF | sudo tee /app/.env.minimal
# Spring Profile
SPRING_PROFILES_ACTIVE=${environment}

# AWS Configuration
AWS_REGION=${aws_region}

# Server Port
SERVER_PORT=${server_port}

# Timezone
TZ=Asia/Seoul

# S3 Buckets
PUBLIC_FILES_BUCKET=${uploads_bucket_name}
PRIVATE_FILES_BUCKET=${private_files_bucket_name}

# CloudFront Configuration (Signed URL용)
CLOUDFRONT_PRIVATE_DISTRIBUTION_DOMAIN=${cloudfront_private_distribution_domain}
CLOUDFRONT_KEY_PAIR_ID=${cloudfront_key_pair_id}
CLOUDFRONT_PRIVATE_KEY_SECRET_NAME=${cloudfront_private_key_secret_name}
EOF

sudo chown ec2-user:ec2-user /app/.env.minimal
sudo chmod 600 /app/.env.minimal

# 참고: DB 비밀번호, JWT Secret, Toss Secret은
# Spring Boot가 런타임에 Secrets Manager에서 직접 조회합니다.
# IAM Role 권한이 이미 설정되어 있습니다.

# Docker Compose 파일 생성 (임시 - 실제로는 Git에서 가져옴)
echo "Creating Docker Compose configuration..."
cat <<EOF | sudo tee /app/docker-compose.yml
version: '3.8'

services:
  app:
    image: ${project_name}-backend:latest
    container_name: ${project_name}-backend
    environment:
      # Spring Profile (나머지는 Secrets Manager에서 조회)
      SPRING_PROFILES_ACTIVE: ${environment}
      AWS_REGION: ${aws_region}
      SERVER_PORT: ${server_port}
      TZ: Asia/Seoul
    ports:
      - "${server_port}:${server_port}"
    volumes:
      - ./uploaded-files:/app/uploaded-files
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:${server_port}/actuator/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
EOF

sudo chown ec2-user:ec2-user /app/docker-compose.yml

# Nginx 설치 (리버스 프록시)
echo "Installing Nginx..."
sudo amazon-linux-extras enable nginx1
sudo yum install -y nginx

# Nginx 설정
echo "Configuring Nginx..."
cat <<EOF | sudo tee /etc/nginx/conf.d/api.conf
upstream backend_app {
    server 127.0.0.1:${server_port};
}

server {
    listen 80;
    server_name %{ if api_domain != "" ~}${api_domain}%{ else ~}_%{ endif ~};

    # CloudFront가 큰 파일도 업로드할 수 있도록 필요한 값만 조정
    client_max_body_size 1G;

    location / {
        proxy_pass http://backend_app;
        proxy_http_version 1.1;
        proxy_set_header Host $$host;
        proxy_set_header X-Real-IP $$remote_addr;
        proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $$scheme;
        proxy_set_header Connection "";
        proxy_read_timeout 300;
        proxy_send_timeout 300;
    }
}
EOF

sudo systemctl start nginx
sudo systemctl enable nginx

# CloudWatch Logs 설정
echo "Configuring CloudWatch Logs..."
# 실제 로그 경로 확인 및 디렉토리 생성 (ssm-user 권한)
# CloudWatch Logs Agent가 읽을 수 있도록 권한 설정
sudo mkdir -p /home/ssm-user/eyet-backend/logs
sudo chown -R ssm-user:ssm-user /home/ssm-user/eyet-backend
# CloudWatch Logs Agent (cwagent 사용자)가 로그 파일을 읽을 수 있도록 권한 부여
sudo chmod -R 755 /home/ssm-user/eyet-backend/logs || true

cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${environment}/application.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "application-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${environment}/access.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "access-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${environment}/error.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "error-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${environment}/sql.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "sql-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${environment}/workflow-scheduler.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "workflow-scheduler-{instance_id}"
          },
          {
            "file_path": "/home/ssm-user/eyet-backend/logs/${environment}/license-subscription-scheduler.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "license-subscription-scheduler-{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "nginx-access-{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/bt-portal-backend/${environment}",
            "log_stream_name": "nginx-error-{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 배포 스크립트 생성
echo "Creating deployment script..."
cat <<'DEPLOY_SCRIPT' | sudo tee /app/deploy.sh
#!/bin/bash
set -e

echo "Starting deployment at $(date)"

# Docker 이미지 빌드 (Git에서 최신 코드 받은 후)
cd /app/bt-portal-backend
git pull origin main

echo "Building Docker image..."
docker build -t ${project_name}-backend:latest .

echo "Stopping existing container..."
cd /app
docker-compose down

echo "Starting new container..."
docker-compose up -d

echo "Deployment completed at $(date)"
DEPLOY_SCRIPT

sudo chmod +x /app/deploy.sh
sudo chown ec2-user:ec2-user /app/deploy.sh

echo "========================================="
echo "User Data Script Completed at $(date)"
echo "========================================="

# 재부팅 후에도 Docker가 실행되도록 설정
sudo systemctl enable docker

echo "Instance is ready for deployment!"


