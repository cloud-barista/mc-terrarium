> _아래 내용은 OpenBao 통합 과정 컨텍스트를 바탕으로 Claude Opus 4.6 모델이 생성하였으며, 부정확한 내용이 포함되어 있을 수 있습니다._

## cb-tumblebug에 mc-terrarium + OpenBao 적용 미리보기

### 1. 메인테이너/기여자 사전 공유 사항

#### 1.1 변경 배경

mc-terrarium에 **OpenBao**(secrets management)가 필수 구성 요소로 추가되었습니다.
기존에는 CSP credential을 env 파일로 직접 컨테이너에 주입했지만,
이제 OpenBao에 암호화 저장하고 API로 접근하는 방식으로 전환되었습니다.

#### 1.2 cb-tumblebug에 미치는 영향

| 항목                | 기존                     | 변경 후                                                       |
| ------------------- | ------------------------ | ------------------------------------------------------------- |
| mc-terrarium 의존성 | mc-terrarium 단독        | mc-terrarium + openbao (2개 서비스)                           |
| CSP credential 전달 | env_file로 직접 주입     | OpenBao KV v2에 저장, terrarium이 API로 조회                  |
| 초기화 절차         | 없음 (env_file 마운트만) | `bash init/init.sh` (OpenBao init + unseal + credential 등록) |
| 재시작 시           | 별도 작업 없음           | auto-unseal 처리 (Makefile 자동화 완료)                       |
| 환경변수            | 없음                     | `VAULT_TOKEN`, `VAULT_ADDR` 추가 (.env)                       |
| 네트워크            | external_network만 사용  | internal_network + external_network                           |

#### 1.3 cb-tumblebug 자체에 코드 변경은 없음

- cb-tumblebug은 mc-terrarium을 **REST API**로만 호출 (loose coupling)
- terrarium의 내부 credential 관리 방식 변경은 tumblebug에 투명
- `TB_TERRARIUM_REST_URL=http://mc-terrarium:8055/terrarium` 변경 없음
- tumblebug Go 코드 수정 불필요

#### 1.4 주의 사항

- **docker-compose.yaml의 mc-terrarium 섹션을 주석 해제할 때**, 기존 env_file 방식 대신 OpenBao 연동 구성으로 교체 필요
- **OpenBao 포트(8200)** 추가 노출 — 개발 환경에서 호스트 접근용
- **`.env` 파일에 `VAULT_TOKEN` 추가** 필요
- **첫 구동 시 `init/init.sh` 실행** 필요 (OpenBao 초기화 + credential 등록)
- container-volume 삭제 시 OpenBao 데이터도 삭제됨 → 재초기화 필요

---

### 2. 적용 후 달라지는 활용 방법

#### 2.1 기존 워크플로우

```
1. docker compose up -d
   → mc-terrarium이 env_file에서 CSP credential 로드
   → 바로 사용 가능
```

#### 2.2 변경 후 워크플로우

```
최초 구동:
1. docker compose up -d
   → mc-terrarium + openbao 컨테이너 시작
   → openbao는 미초기화 상태 (healthy but uninitialized)
   → mc-terrarium은 openbao healthy 대기 후 시작

2. bash init/init.sh
   → OpenBao 초기화 (unseal key + root token 생성 → .env에 기록)
   → OpenBao unseal
   → CSP credentials를 ~/.cloud-barista/credentials.yaml.enc에서
     복호화하여 OpenBao KV v2에 등록

3. (선택) docker compose restart mc-terrarium
   → VAULT_TOKEN이 .env에 기록된 후 mc-terrarium 재시작하여 반영

재시작:
1. docker compose up -d  (또는 make compose-up)
   → openbao 컨테이너 시작 (sealed 상태)
   → auto-unseal 스크립트 자동 실행
   → mc-terrarium 정상 동작
```

#### 2.3 Makefile 타겟 변화

```makefile
# cb-tumblebug Makefile에 추가될 수 있는 패턴 (참고)
compose:       # docker compose up --build -d + auto-unseal
compose-up:    # docker compose up -d + auto-unseal
compose-down:  # docker compose down
init:          # bash init/init.sh (기존 tumblebug init + terrarium init 통합 가능)
```

#### 2.4 credential 관리 방법 변화

| 작업            | 기존                                                | 변경 후                                                                                                  |
| --------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| credential 추가 | env 파일 생성 + docker-compose.yaml에 env_file 추가 | `init/init.sh --credentials-only`                                                                        |
| credential 확인 | 파일 직접 열기                                      | `curl -s -H "X-Vault-Token: $VAULT_TOKEN" http://localhost:8200/v1/secret/data/csp/aws \| jq .data.data` |
| credential 갱신 | 파일 수정 + 컨테이너 재시작                         | `init/init.sh --credentials-only` (재시작 불필요)                                                        |
| 지원 CSP        | AWS, Azure, GCP, Alibaba, IBM, NCP, DCS             | 동일 + Tencent (8개 CSP)                                                                                 |

---

### 3. cb-tumblebug에 추가/수정해야 하는 파일

#### 3.1 `docker-compose.yaml` (수정)

**현재 상태:** mc-terrarium 섹션이 주석 처리되어 있음 (lines 274-320)

**변경 내용:**

- 기존 주석 처리된 mc-terrarium 섹션 제거
- mc-terrarium + openbao 서비스 추가 (mc-terrarium의 docker-compose.yaml 내용 기반)
- `terrarium_network` → `internal_network` 사용으로 단순화
- env_file 방식 제거 → VAULT_ADDR + VAULT_TOKEN 환경변수 추가
- openbao healthcheck 포함
- mc-terrarium의 `depends_on: openbao` 설정

**주요 변경 포인트:**

```yaml
# 추가할 서비스 (2개)

# mc-terrarium + OpenBao
mc-terrarium:
  image: cloudbaristaorg/mc-terrarium:0.0.22
  container_name: mc-terrarium
  networks:
    - internal_network
    - external_network
  ports:
    - 8055:8055
  volumes:
    - ./container-volume/mc-terrarium-container/.terrarium:/app/.terrarium
    - /etc/ssl/certs:/etc/ssl/certs:ro
  environment:
    - TERRARIUM_ROOT=/app
    - TERRARIUM_LOGLEVEL=info
    - VAULT_ADDR=http://openbao:8200
    - VAULT_TOKEN=${VAULT_TOKEN:-}
  depends_on:
    openbao:
      condition: service_healthy
  healthcheck:
    test:
      [
        "CMD",
        "wget",
        "-q",
        "-O",
        "/dev/null",
        "http://localhost:8055/terrarium/readyz",
      ]
    interval: 10m
    timeout: 5s
    retries: 3
    start_period: 10s
  restart: unless-stopped

openbao:
  image: openbao/openbao:2.5.1
  container_name: openbao
  cap_add:
    - IPC_LOCK
  networks:
    - internal_network
    - external_network
  ports:
    - 8200:8200
  environment:
    - BAO_ADDR=http://0.0.0.0:8200
    - SKIP_SETCAP=true
  command: server -config=/openbao/config/openbao-config.hcl
  volumes:
    - ./container-volume/openbao-data:/openbao/data
    - ./conf/openbao-config.hcl:/openbao/config/openbao-config.hcl:ro
  healthcheck:
    test: ["CMD", "sh", "-c", "rc=0; bao status || rc=$$?; [ $$rc -le 2 ]"]
    interval: 10s
    timeout: 5s
    retries: 3
    start_period: 5s
  restart: unless-stopped
```

**제거할 항목:**

- `terrarium_network` 네트워크 정의 (lines 6-7, 주석 상태)
- cb-tumblebug 서비스의 `terrarium_network` 참조 (line 38, 주석 상태)
- 기존 주석 처리된 mc-terrarium 섹션 (lines 274-320)

---

#### 3.2 `.env` (수정)

**현재 내용:**

```dotenv
SP_API_USERNAME=...
SP_API_PASSWORD=...
TB_API_USERNAME=default
TB_API_PASSWORD=default
```

**추가할 내용:**

```dotenv
## OpenBao (for mc-terrarium)
VAULT_TOKEN=root-token
VAULT_ADDR=http://localhost:8200
```

- `VAULT_TOKEN`: `init/init.sh` 실행 시 자동으로 실제 token으로 갱신
- `VAULT_ADDR`: 호스트에서 OpenBao 접근 시 사용

---

#### 3.3 `conf/openbao-config.hcl` (신규)

mc-terrarium의 `conf/openbao-config.hcl`과 동일한 파일을 복사:

```hcl
storage "file" {
  path = "/openbao/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr = "http://0.0.0.0:8200"
disable_mlock = true
ui = true
```

---

#### 3.4 `init/init.sh` (수정)

**현재:** cb-tumblebug 자체 초기화만 수행 (credential 등록 → load assets → fetch price)

**변경 방안 (2가지 옵션):**

**옵션 A — terrarium init 호출 추가 (권장)**

```bash
# init.sh 상단에 terrarium init 호출 추가
echo "Initializing mc-terrarium (OpenBao + CSP credentials)..."
TERRARIUM_INIT="../mc-terrarium/init/init.sh"
if [ -f "$TERRARIUM_INIT" ]; then
    bash "$TERRARIUM_INIT" "$@"
fi
# 이후 기존 tumblebug 초기화 로직...
```

**옵션 B — 별도 스크립트**

- `init/init-terrarium.sh` 추가
- Makefile에 `init-terrarium` 타겟 추가

---

#### 3.5 `init/unseal-openbao.sh` (신규 또는 심볼릭 링크)

mc-terrarium의 `init/unseal-openbao.sh`를 cb-tumblebug에서도 사용할 수 있도록:

**옵션 A — mc-terrarium의 스크립트 직접 호출**

```bash
# Makefile 또는 compose-up에서
bash ../mc-terrarium/init/unseal-openbao.sh || true
```

**옵션 B — 복사**

- `init/unseal-openbao.sh`를 cb-tumblebug에 복사

---

#### 3.6 `.gitignore` (수정)

**추가할 항목:**

```gitignore
# OpenBao init output (contains unseal key + root token)
secrets/openbao-init.json
```

---

#### 3.7 `Makefile` (수정)

**추가할 내용:**

```makefile
# compose 타겟에 auto-unseal 추가
compose: ## Start Docker Compose services with --build
	DOCKER_BUILDKIT=1 docker compose up --build -d
	@bash init/unseal-openbao.sh || true
```

---

#### 3.8 `secrets/` 디렉토리 (신규)

```
secrets/
  openbao-init.json   # init 시 자동 생성 (.gitignore에 추가)
```

---

### 4. 파일 변경 요약

| 파일                      | 작업     | 설명                                                    |
| ------------------------- | -------- | ------------------------------------------------------- |
| `docker-compose.yaml`     | **수정** | mc-terrarium + openbao 서비스 추가, 기존 주석 섹션 제거 |
| `.env`                    | **수정** | `VAULT_TOKEN`, `VAULT_ADDR` 추가                        |
| `conf/openbao-config.hcl` | **신규** | OpenBao 서버 설정 파일                                  |
| `init/init.sh`            | **수정** | terrarium init 호출 추가 (옵션)                         |
| `init/unseal-openbao.sh`  | **신규** | auto-unseal 스크립트 (복사 또는 참조)                   |
| `.gitignore`              | **수정** | `secrets/openbao-init.json` 추가                        |
| `Makefile`                | **수정** | compose 타겟에 auto-unseal 추가                         |
| `secrets/`                | **신규** | openbao-init.json 저장 디렉토리                         |

---

### 5. 단계별 적용 순서 (권장)

```
1. conf/openbao-config.hcl 추가
2. docker-compose.yaml에 openbao + mc-terrarium 서비스 추가
3. .env에 VAULT_TOKEN, VAULT_ADDR 추가
4. .gitignore에 secrets/openbao-init.json 추가
5. init/unseal-openbao.sh 추가 (mc-terrarium에서 복사)
6. Makefile compose 타겟에 auto-unseal 추가
7. docker compose up -d → bash init/init.sh
8. 동작 확인 (VPN/SQL DB API 호출 테스트)
```
