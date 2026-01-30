# k8s-local: Minikube Spring Boot 모니터링 환경

로컬 Minikube 환경에서 Spring Boot 애플리케이션을 배포하고 PLG 스택(Prometheus + Loki + Grafana)으로 모니터링하는 학습 환경.

## 구조

```
k8s-local/
├── namespace.yaml                    # monitoring 네임스페이스
├── app/
│   ├── deployment.yaml               # Spring Boot 앱 배포
│   └── service.yaml                  # 앱 서비스 (NodePort 30080)
└── monitoring/
    ├── prometheus/
    │   ├── rbac.yaml                 # ServiceAccount, ClusterRole
    │   ├── configmap.yaml            # Prometheus 스크래핑 설정
    │   └── deployment.yaml           # Prometheus 배포 + 서비스 (NodePort 30090)
    ├── loki/
    │   ├── configmap.yaml            # Loki 설정 (스토리지, 스키마)
    │   └── deployment.yaml           # Loki 배포 + 서비스 (ClusterIP 3100)
    ├── promtail/
    │   ├── configmap.yaml            # Promtail 스크래핑 설정
    │   └── daemonset.yaml            # Promtail DaemonSet + RBAC
    └── grafana/
        ├── datasource.yaml           # Prometheus + Loki 데이터소스 자동 연결
        ├── dashboard-provider.yaml   # 대시보드 프로비저닝 설정
        ├── dashboard-spring.yaml     # Spring Boot 대시보드 (JSON)
        └── deployment.yaml           # Grafana 배포 + 서비스 (NodePort 30030)
```

## 사전 준비

### 1. Minikube 설치 및 시작

```bash
# Minikube 시작
minikube start --memory=4096 --cpus=2

# 상태 확인
minikube status
```

### 2. Spring Boot 의존성 추가

`build.gradle` 또는 `pom.xml`에 아래 의존성 추가:

```groovy
// build.gradle
implementation 'org.springframework.boot:spring-boot-starter-actuator'
runtimeOnly 'io.micrometer:micrometer-registry-prometheus'
```

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
    <scope>runtime</scope>
</dependency>
```

### 3. application.yml 설정

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, prometheus, metrics
  metrics:
    tags:
      application: spring-app
```

### 4. Spring Boot 이미지 빌드 (Minikube Docker 데몬 사용)

```bash
# Minikube Docker 데몬으로 전환
eval $(minikube docker-env)

# 이미지 빌드
docker build -t spring-app:latest .
```

## 배포

```bash
# 1. monitoring 네임스페이스 생성
kubectl apply -f namespace.yaml

# 2. Prometheus RBAC + 설정 + 배포
kubectl apply -f monitoring/prometheus/

# 3. Loki 배포
kubectl apply -f monitoring/loki/

# 4. Promtail 배포 (모든 노드에서 로그 수집)
kubectl apply -f monitoring/promtail/

# 5. Grafana 배포
kubectl apply -f monitoring/grafana/

# 6. Spring Boot 앱 배포
kubectl apply -f app/
```

## 접속

```bash
# Spring Boot 앱
minikube service spring-app --url

# Prometheus UI
minikube service prometheus -n monitoring --url

# Grafana UI
minikube service grafana -n monitoring --url
```

| 서비스     | NodePort | 기본 계정     |
| ---------- | -------- | ------------- |
| Spring App | 30080    | -             |
| Prometheus | 30090    | -             |
| Grafana    | 30030    | admin / admin |

## Grafana 대시보드

Grafana 접속 후 자동으로 "Spring Boot Overview" 대시보드가 프로비저닝됨.

**메트릭 패널 (Prometheus):**

- HTTP Request Rate / Response Time (p95)
- JVM Heap Memory / GC Pause Time
- Active Threads / CPU Usage / Uptime
- HTTP 5xx Error Rate
- HikariCP Connection Pool
- Logback Log Events Rate

**로그 조회 (Loki):**
Grafana 좌측 메뉴 > Explore > 데이터소스를 "Loki"로 선택 후 LogQL로 조회.

```
# Spring 앱 로그 조회
{app="spring-app"}

# ERROR 레벨만 필터링
{app="spring-app"} |= "ERROR"

# 특정 네임스페이스의 모든 로그
{namespace="default"}
```

## 전체 삭제

```bash
kubectl delete -f app/
kubectl delete -f monitoring/grafana/
kubectl delete -f monitoring/promtail/
kubectl delete -f monitoring/loki/
kubectl delete -f monitoring/prometheus/
kubectl delete -f namespace.yaml
```
