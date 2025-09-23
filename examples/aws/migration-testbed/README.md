# AWS Migration Testbed

이 테스트베드는 AWS에 6대의 VM을 생성하여 마이그레이션 시나리오를 테스트하기 위한 환경을 구성합니다.

## VM 구성

각 VM은 서로 다른 사양과 방화벽 규칙을 가지고 있습니다:

| VM  | vCPU | Memory | Instance Type | Firewall Rules | 용도                            |
| --- | ---- | ------ | ------------- | -------------- | ------------------------------- |
| vm1 | 2    | 4 GB   | t3.small      | 3개            | 웹 서버 (HTTP/HTTPS/MySQL)      |
| vm2 | 2    | 16 GB  | t3.xlarge     | 4개            | API 서버 (API/Redis/MongoDB/ES) |
| vm3 | 4    | 8 GB   | t3.large      | 5개            | 애플리케이션 서버               |
| vm4 | 4    | 16 GB  | m5.xlarge     | 8개            | 로드밸런서 & 클러스터           |
| vm5 | 8    | 32 GB  | m5.2xlarge    | 10개           | 마이크로서비스 플랫폼           |
| vm6 | 8    | 32 GB  | m5.2xlarge    | 8개            | 컨테이너 오케스트레이션         |

## 사전 요구사항

1. **OpenTofu 설치**

   ```shell
   # Ubuntu/Debian
   curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh
   ```

2. **AWS CLI 구성 및 인증 정보 설정**

   ```shell
   # AWS CLI 설치
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install

   # AWS 자격증명 구성
   aws configure
   ```

   또는 환경변수로 설정:

   ```shell
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="ap-northeast-2"
   ```

3. **필요한 권한**
   - EC2: 인스턴스 생성/삭제, VPC 관리, 보안그룹 관리
   - IAM: 키페어 관리

## 배포 방법

### 설정 파일

이 테스트베드는 두 가지 설정 파일 형식을 지원합니다:

#### 옵션 1: HCL 형식 (추천)

- `terraform.tfvars`: 주석을 포함한 상세 설명이 있는 HCL 형식
- 자동으로 로드됨 (`tofu apply`만으로 실행 가능)
- 주석과 설명이 풍부하여 이해하기 쉬움

#### 옵션 2: JSON 형식

- `terraform.tfvars.json`: 간결한 JSON 형식
- 명시적 지정 필요 (`tofu apply -var-file=terraform.tfvars.json`)
- 프로그래밍 방식 생성에 적합

**설정 가능한 항목:**

- `terrarium_id`: 인프라 고유 ID
- `aws_region`: AWS 리전 (기본: ap-northeast-2)
- `allowed_cidr_blocks`: 추가 접근 허용 CIDR 블록
- `vm_configurations`: 각 VM의 스펙과 서비스 역할

### 기본 배포 (HCL 형식 사용)

1. OpenTofu 초기화:

```shell
tofu init
```

2. 계획 확인:

```shell
tofu plan
```

3. 리소스 배포:

```shell
tofu apply
```

### JSON 형식으로 배포

```shell
tofu apply -var-file=terraform.tfvars.json
```

### 커스텀 설정으로 배포

#### HCL 형식 편집 (추천)

```shell
# 주석이 포함된 설정 파일 편집
vim terraform.tfvars
```

#### JSON 형식 편집

```shell
# 간결한 JSON 형식 편집
vim terraform.tfvars.json
```

#### 설정 예시 (HCL)

```hcl
# 커스텀 설정 예시
terrarium_id = "my-custom-testbed"
aws_region = "us-west-2"

# 추가 네트워크 접근 허용
allowed_cidr_blocks = [
  "203.0.113.100/32",  # 관리자 IP
  "192.168.1.0/24"     # 사무실 네트워크
]

# VM 설정 (일부만 사용 가능)
vm_configurations = {
  vm1 = {
    instance_type = "t3.medium"
    vcpu         = 2
    memory_gb    = 4
    service_role = "nginx"
  }
  # 필요한 VM만 정의
}
```

#### 배포 실행

```shell
# HCL 형식 (자동 로드)
tofu plan
tofu apply

# JSON 형식 (명시적 지정)
tofu plan -var-file=terraform.tfvars.json
tofu apply -var-file=terraform.tfvars.json
```

## SSH 접속 설정

1. Private key를 파일로 저장:

```shell
tofu output -json ssh_info | jq -r .private_key > private_key.pem
chmod 600 private_key.pem
```

## VM별 접속 방법

### 모든 VM 정보 확인

```shell
# VM 요약 정보
tofu output vm_summary

# 상세 VM 정보
tofu output vm_details

# SSH 접속 정보
tofu output -json ssh_info | jq .vms

# VM별 SSH 명령어만 추출
tofu output -json ssh_info | jq -r '.vms[] | .command'
```

### 개별 VM 접속

```shell
# VM1 접속
ssh -i private_key.pem ubuntu@$(tofu output -json vm_summary | jq -r .vm1.public_ip)

# VM2 접속
ssh -i private_key.pem ubuntu@$(tofu output -json vm_summary | jq -r .vm2.public_ip)

# VM3 접속
ssh -i private_key.pem ubuntu@$(tofu output -json vm_summary | jq -r .vm3.public_ip)

# VM4 접속
ssh -i private_key.pem ubuntu@$(tofu output -json vm_summary | jq -r .vm4.public_ip)

# VM5 접속
ssh -i private_key.pem ubuntu@$(tofu output -json vm_summary | jq -r .vm5.public_ip)

# VM6 접속
ssh -i private_key.pem ubuntu@$(tofu output -json vm_summary | jq -r .vm6.public_ip)
```

## 방화벽 규칙 정보 확인

```shell
# 보안 그룹 및 방화벽 규칙 정보
tofu output security_groups
```

## 테스트베드 정보 확인

```shell
# 인프라 정보
tofu output testbed_info
```

## 리소스 정리

테스트 완료 후 리소스를 정리합니다:

```shell
tofu destroy
```

## 방화벽 규칙 상세

### VM1 (웹 서버)

- HTTP (80): 웹 트래픽
- HTTPS (443): 보안 웹 트래픽
- MySQL (3306): 데이터베이스 접근

### VM2 (API 서버)

- API Server (8080): API 엔드포인트
- Redis (6379): 캐시 서버
- MongoDB (27017): NoSQL 데이터베이스
- Elasticsearch (9200): 검색 엔진

### VM3 (애플리케이션 서버)

- Web Server (80/443): 웹 서비스
- App Server (8000): 애플리케이션 서버
- PostgreSQL (5432): 관계형 데이터베이스
- Memcached (11211): 메모리 캐시

### VM4 (로드밸런서 & 클러스터)

- Load Balancer (80/443): 부하 분산
- App Cluster (8080-8090): 애플리케이션 클러스터
- Database Cluster (3306): DB 클러스터
- Cache Cluster (6379-6389): 캐시 클러스터
- Message Queue (5672): RabbitMQ
- Monitoring (9090): Prometheus
- Logging (5044): Logstash

### VM5 (마이크로서비스 플랫폼)

- API Gateway (80/443): API 게이트웨이
- Microservices (8000-8020): 마이크로서비스 포트
- Database Master (5432): 마스터 DB
- NoSQL Cluster (27017-27019): MongoDB 클러스터
- Search Engine (9200-9300): Elasticsearch 클러스터
- Cache Redis (6379): Redis 캐시
- Streaming (9092): Kafka
- Metrics (3000): Grafana 대시보드
- Container Registry (5000): Docker 레지스트리

### VM6 (컨테이너 오케스트레이션)

- Kubernetes API (6443): K8s API 서버
- Kubelet (10250): Kubelet API
- etcd Cluster (2379-2380): etcd 클러스터
- Ingress Controller (80/443): 인그레스 컨트롤러
- NodePort Services (30000-32767): K8s NodePort
- Container Logs (24224): Fluentd 로그 수집
- Service Mesh (15000-15010): Istio 서비스 메시

1. Run the following command

```shell
tofu state rm aws_route_table.imported_route_table
```

2. Truncate `imports.tf` and perform tofu destroy.

## Note

This testbed uses OpenTofu. Make sure to use `tofu` commands.
