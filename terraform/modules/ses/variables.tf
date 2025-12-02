variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (local, dev, prod 등)"
  type        = string
}

variable "domain_name" {
  description = "SES에서 사용할 도메인 이름"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 호스팅 존 ID (도메인 인증 자동화용, 비어있으면 수동 설정 필요)"
  type        = string
  default     = ""
}

variable "verified_email_addresses" {
  description = "인증할 이메일 주소 목록 (도메인 인증 대신 이메일 주소 인증 사용 시)"
  type        = list(string)
  default     = []
}

variable "enable_dmarc" {
  description = "DMARC 레코드 활성화 여부"
  type        = bool
  default     = false
}

variable "dmarc_email" {
  description = "DMARC 리포트를 받을 이메일 주소 (enable_dmarc가 true일 때 필요)"
  type        = string
  default     = ""
}

variable "dmarc_policy" {
  description = "DMARC 정책 레벨 (none: 모니터링만, quarantine: 스팸함으로 이동, reject: 완전 차단)"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "DMARC 정책은 none, quarantine, reject 중 하나여야 합니다."
  }
}

