> _이 문서는 Claude Opus 4.6 모델이 생성하였으며, 부정확한 내용이 포함되어 있을 수 있습니다._

> [!NOTE]
> 전체적인 방향, 큰 그림 등이 지금까지 파악한 내용과 유사하여 공유드리며,
> 세부 사항이 다를 수 있으니 주의하시기 바랍니다.

# OpenBao 도입 현황 및 향후 과제

## OpenBao 도입 배경

**문제: CSP Credential의 평문 노출**

```
기존                              개선 후
┌─────────────────────┐          ┌─────────────────────┐
│ .env 파일 (평문)     │          │ OpenBao (암호화 저장) │
│ credential-*.env    │          │                     │
│   → docker inspect  │          │ .env에는 token만    │
│   → /proc 노출      │          │   → credential 없음  │
│   → 로그 노출       │          │   → 폐기/갱신 가능   │
│   → Git 실수 노출   │          │                     │
└─────────────────────┘          └─────────────────────┘
```

**도입 효과:**

- Credential이 평문 파일로 존재하지 않음
- 암호화된 상태로 저장 (Seal Key 보호)
- 중앙 집중 관리 → 산재된 env 파일 제거

---

## 현재 구조 — 단일 사용자, 로컬 환경

```
개발자 (관리자 = 사용자)
    │
    │ bash init/init.sh
    │   1. OpenBao 초기화 (unseal key + root token 생성)
    │   2. CSP credential 등록 (credentials.yaml.enc → OpenBao)
    │
    ▼
┌──────────┐    VAULT_TOKEN    ┌──────────┐
│ .env     │ ───────────────→  │ OpenBao  │
│ (token)  │                   │ KV v2    │
└──────────┘                   │ secret/  │
                               │  csp/    │
┌──────────────┐  API 요청     │   aws    │
│ mc-terrarium │ ────────────→ │   gcp    │
│ (컨테이너)    │  token 인증   │   azure  │
└──────────────┘               │   ...    │
                               └──────────┘
```

**현재 한계:**

- Root token 직접 사용 (전체 권한)
- `.env`에 token 평문 저장
- 단일 서비스만 접근

→ **로컬 개발 환경에서는 적절한 수준**

---

## 과제 1 — 접근 권한 분리 (Policy + AppRole)

**여러 서비스가 OpenBao를 공유할 때**

```
┌─────────────────────────────────────────────┐
│                  OpenBao                     │
│                                             │
│  Policy A: secret/csp/* (read)              │
│  Policy B: secret/infra/* (read/write)      │
│  Policy C: secret/csp/aws (read only)       │
│                                             │
│  AppRole: terrarium  → Policy A             │
│  AppRole: tumblebug  → Policy B             │
│  AppRole: monitor    → Policy C             │
└─────────────────────────────────────────────┘
         ▲           ▲           ▲
         │           │           │
   mc-terrarium  cb-tumblebug  모니터링
   (CSP 전체읽기) (인프라 관리)  (AWS만 읽기)
```

**필요 작업:**

- 서비스별 Policy 정의 (최소 권한 원칙)
- AppRole 생성 및 role-id/secret-id 발급
- mc-terrarium Go 코드에 AppRole login 로직 추가
- Root token은 관리 작업에만 사용

---

## 과제 2 — Token 생명주기 관리

**Token이 영구적이면 유출 시 피해가 지속됨**

```
현재                              개선 후
┌──────────────┐                 ┌──────────────┐
│ Root Token   │                 │ 임시 Token    │
│ TTL: ∞       │                 │ TTL: 1h       │
│ 권한: 전체    │                 │ 권한: 제한     │
│ 폐기: 수동    │                 │ 폐기: 자동     │
└──────────────┘                 └──────────────┘

                    ┌─ 갱신 주기 ─┐
                    │             │
            서비스 시작 → login → token 획득 (1h)
                              → 만료 전 갱신
                              → 서비스 종료 시 폐기
```

**필요 작업:**

- Token TTL 설정 (`token_ttl=1h`, `token_max_ttl=4h`)
- 서비스 내 token 자동 갱신 로직
- Token 폐기 (revoke) API 호출 on shutdown

---

## 과제 3 — 감사 로깅 (Audit)

**누가, 언제, 무엇을 읽었는지 추적**

```
$ bao audit enable file file_path=/openbao/logs/audit.log

# 로그 예시
{
  "time": "2026-02-24T10:30:00Z",
  "auth": { "token_type": "service", "policies": ["terrarium-policy"] },
  "request": {
    "path": "secret/data/csp/aws",
    "operation": "read"
  }
}
```

**필요 작업:**

- Audit backend 활성화 (file 또는 syslog)
- 로그 수집/모니터링 연동
- 비정상 접근 패턴 알림 설정

---

## 과제 4 — Secret 주입 방식 개선

**`.env` 파일 → 안전한 전달 경로**

| 단계   | 방식                         | Token 저장 위치        | 디스크 노출          |
| ------ | ---------------------------- | ---------------------- | -------------------- |
| 현재   | `.env` 파일                  | 파일 시스템 (평문)     | O                    |
| 개선 1 | 환경변수 직접 주입           | 프로세스 메모리        | X                    |
| 개선 2 | Token wrapping               | 일회용 wrapping token  | X (1회 사용 후 폐기) |
| 개선 3 | Docker Secrets / K8s Secrets | tmpfs (메모리)         | X                    |
| 개선 4 | Vault Agent sidecar          | 자동 인증 + token 관리 | X                    |

---

## 단계별 로드맵

```
Phase 1 (현재) ✅                Phase 2                    Phase 3
로컬 개발 환경                   멀티 서비스 환경             운영 환경
─────────────                   ─────────────              ─────────────
✅ OpenBao 도입                  □ Policy 정의              □ TLS 활성화
✅ KV v2 credential 저장         □ AppRole 인증             □ Audit 로깅
✅ 자동 init/unseal              □ Token TTL 적용           □ Auto-unseal (클라우드 KMS)
✅ 암호화 저장                    □ 서비스별 권한 분리        □ HA 구성 (Raft)
✅ Root token 사용               □ Root token 봉인          □ Secret 자동 rotation
                                □ Token wrapping           □ K8s 연동
```

---

## 요약

| 관점           | 현재 (Phase 1)  | 향후 필요 사항             |
| -------------- | --------------- | -------------------------- |
| **인증**       | Root token      | AppRole (서비스별 인증)    |
| **권한**       | 전체 접근       | Policy (최소 권한)         |
| **Token 수명** | 영구            | TTL + 자동 갱신/폐기       |
| **Token 저장** | `.env` 평문     | 메모리 주입 / wrapping     |
| **감사**       | 없음            | Audit 로그 + 모니터링      |
| **통신**       | HTTP (내부망)   | TLS (HTTPS)                |
| **가용성**     | 단일 인스턴스   | HA (Raft consensus)        |
| **Unseal**     | 수동 (스크립트) | Auto-unseal (클라우드 KMS) |
