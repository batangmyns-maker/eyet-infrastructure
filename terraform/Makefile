# Makefile - Terraform 프로젝트용
# 사용법: make <command>

.PHONY: help init-prod init-local clean

# 기본 명령어 (make만 입력 시)
help:
	@echo "사용 가능한 명령어:"
	@echo "  make init         - Terraform 초기화"
	@echo "  make plan         - Plan 실행"
	@echo "  make apply        - Apply 실행"
	@echo "  make clean        - .terraform 디렉토리 삭제"

# ============================================================
# Terraform 명령어
# ============================================================

init: clean
	@echo "🚀 Terraform 초기화 중..."
	terraform init
	@echo "✅ 초기화 완료!"

plan:
	@echo "📋 Plan 실행 중..."
	terraform plan
	@echo "✅ Plan 완료!"

apply:
	@echo "🔨 Apply 실행 중..."
	terraform apply
	@echo "✅ Apply 완료!"

# ============================================================
# Utility 명령어
# ============================================================

clean:
	@echo "🧹 .terraform 디렉토리 정리 중..."
	rm -rf .terraform .terraform.lock.hcl
	@echo "✅ 정리 완료!"

