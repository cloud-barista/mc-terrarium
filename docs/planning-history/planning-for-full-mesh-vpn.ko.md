# 소규모 Full-Mesh VPN 구성 플래닝

> **작성일**: 2026년 3월 5일
> **상태**: 아카이브 (Archive) — 구현 보류  
> **결론**: 소규모(2~7개 CSP) Full-Mesh VPN 구성은 기술적으로 설계 가능하나, 아래 제약사항들로 인해 현 시점에서 추진하기에는 시기상조로 판단됨. 향후 CSP 지원 범위 확대 또는 아키텍처 변경 시 재검토 예정.
> **공동 작성**: GitHub Copilot (Claude Opus 4.6)과 작성자의 약 30회에 걸친 질의 응답 및 검토를 통해 작성됨
>
> **영문 버전**: [planning-for-full-mesh-vpn.md](planning-for-full-mesh-vpn.md)

### 도출된 주요 제약사항

| #   | 제약사항                            | 심각도   | 설명                                                                                                                                                                      |
| --- | ----------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **GCP ↔ Static CSP 직접 연결 불가** | Critical | GCP HA VPN은 BGP를 필수 요구하나, Tencent·IBM·DCS는 BGP 미지원. 7개 CSP Full-Mesh 시 3쌍(GCP↔Tencent, GCP↔IBM, GCP↔DCS)이 구성 불가하여 완전한 Full-Mesh를 달성할 수 없음 |
| 2   | **Transit Routing 미지원**          | Critical | 모든 CSP VPN Gateway는 BGP 학습 경로를 재광고하지 않음. Partial Mesh 시 경유 통신 불가 → 반드시 Full-Mesh 필요. 그러나 제약 #1로 인해 7-CSP Full-Mesh 자체가 불가능       |
| 3   | **AWS VGW 10 Connection 제한**      | High     | AWS VPN Gateway당 최대 10개 VPN Connection. CSP당 2 Connection 기준 최대 5개 원격 CSP만 연결 가능 → 6개 이상 CSP 동시 연결 시 Quota 초과                                  |
| 4   | **12개 Connection 모듈 미구현**     | High     | Full-Mesh $\binom{7}{2} = 21$ 쌍 중 3개만 구현됨(conn-aws-azure, conn-azure-gcp, conn-alibaba-azure). 나머지 12개(+불가 6개) 모듈 개발에 상당한 공수 소요                 |
| 5   | **Azure APIPA 주소 범위 제한**      | Medium   | BGP Peering에 사용되는 APIPA 범위가 169.254.21.0~169.254.22.255로 제한됨. 다수 CSP 동시 연결 시 주소 할당 관리 복잡                                                       |
| 6   | **Apply 시간**                      | Medium   | N개 CSP VPN Gateway 동시 생성 시 30~60분 소요 예상                                                                                                                        |

> **참고**: 제약 #1과 #2의 조합이 가장 치명적임. GCP를 포함하는 Full-Mesh에서 Static CSP(Tencent, IBM, DCS)와의 직접 연결이 불가능하고, Transit Routing으로 대체할 수도 없으므로, 7-CSP 완전 Full-Mesh는 현재 CSP 기술 수준에서 달성 불가. BGP 지원 4-CSP(AWS, Azure, GCP, Alibaba)로 범위를 축소하면 Full-Mesh 가능하나, 이 경우 Tencent·IBM·DCS 사용자를 배제하게 됨.

---

## 1. 개요

### 1.1. 목표

N개 CSP의 VPC/VNet을 서로 연결하는 Full-Mesh VPN 구성:

```
      AWS ──── Azure
     / | \    / | \
   GCP |  \ /  | Tencent
    \  |   X   |  /
     \ |  / \  | /
   Alibaba── IBM
```

- 7개 CSP: AWS, Azure, GCP, Alibaba, Tencent, IBM, DCS
- Full-Mesh 조합: $\binom{7}{2} = 21$ 개 pair (단, GCP ↔ Static CSP 3쌍은 기술적 제약으로 구성 불가)
- 사용자가 원하는 CSP 조합만 선택하여 VPN 구성 가능

### 1.2. 핵심 도전과제

| 도전과제                       | 설명                                                                    |
| ------------------------------ | ----------------------------------------------------------------------- |
| **VPN Gateway 단일성 제약**    | AWS VPC당 VGW 1개, Azure VNet당 VPN GW 1개 → 하나의 GW에 여러 연결 필수 |
| **OpenTofu State 관리**        | N-CSP 관리 시 State 크기 및 Apply 시간 증가                             |
| **APIPA 주소 충돌**            | Azure APIPA 범위(169.254.21.0~169.254.22.255) 내 CSP별 할당 관리 필요   |
| **CSP 터널/Connection Quota**  | AWS VGW 최대 10 Connection, GW당 터널 수 제한 등                        |
| **BGP 미지원 CSP**             | Tencent, IBM, DCS는 Static routing만 지원                               |
| **GCP ↔ Static CSP 연결 불가** | GCP HA VPN은 BGP 필수 → Tencent, IBM, DCS와 직접 VPN 연결 불가 (§2.12)  |
| **Transit Routing 미지원**     | CSP VPN GW는 학습한 경로를 재광고하지 않음 → Full-Mesh 필수 (§2.11)     |

### 1.3. 현재 상태 요약

| 구현             | 상태      | 설명                                                                                 |
| ---------------- | --------- | ------------------------------------------------------------------------------------ |
| **aws-to-site**  | 완성      | AWS를 hub로 GCP, Azure, Alibaba, Tencent, IBM, DCS에 연결 (Star 토폴로지)            |
| **site-to-site** | 부분 완성 | CSP 간 대칭 Pair VPN (conn-aws-azure, conn-azure-gcp, conn-alibaba-azure 3개만 구현) |

> 현재 상태에 대한 상세 분석은 [Appendix A](#appendix-a-현재-상태-분석)를 참조하십시오.

### 1.4. 방안 검토 요약

여러 방안을 검토한 결과, **Option D(Single-Terrarium Incremental Composition)** 를 권장합니다:

| 항목           | Option A (Full Mesh) | Option B (Hub-Spoke)  | Option C (GW 분리)     | **Option D (점진적 구성)**  |
| -------------- | -------------------- | --------------------- | ---------------------- | --------------------------- |
| 구현 복잡도    | 중                   | 낮음                  | **높음**               | **중~낮음**                 |
| 사용자 복잡도  | 낮음                 | 낮음                  | **높음**               | **낮음**                    |
| 연결 제거      | 어려움 (전체 재구성) | 쉬움 (독립 terrarium) | 중간 (state 교차 해제) | **쉬움 (Targeted Destroy)** |
| Gateway 공유   | 자연스러움           | 불가 (GW 중복)        | 완전 지원              | **자연스러움**              |
| 점진적 확장    | 불가                 | 가능                  | 가능                   | **가능**                    |
| State 관리     | 대형 (비효율)        | 분산 (효율)           | 분산 (효율)            | 중간 (실용적)               |
| 기존 코드 활용 | 높음                 | 중간                  | 낮음 (새 구조)         | **높음**                    |
| 단기 적용성    | 낮음                 | 중간                  | 낮음                   | **높음**                    |

> 다른 방안에 대한 상세 분석은 [Appendix B](#appendix-b-다른-방안-검토-options-a-b-c)를 참조하십시오.

---

## 2. Option D: Single-Terrarium Incremental Composition

### 2.1. 핵심 아이디어

**하나의 Terrarium에서 N-CSP의 모든 VPN Gateway와 Connection을 일괄 생성/삭제하는 것을 중점 기능으로 제공하며, Connection의 점진적 추가/제거는 선택적 확장 기능으로 지원하는 구조**

- **Primary**: N개 CSP 지정 → 모든 Gateway + 모든 $\binom{N}{2}$ Connection을 일괄 생성/삭제
- **Optional**: `.tf` 파일을 추가 → `tofu apply` → 해당 리소스만 생성 (증분 추가)
- **Optional**: `tofu destroy -target=module.conn_{pair}` → 성공 → `.tf` 파일 삭제 → 해당 리소스만 파기
- Full-Mesh 보장 → Transit Routing 불필요 (§2.11)

```
                     ┌─────────────────────────────────────────┐
                     │   Single Terrarium (.terrarium/{trId})  │
                     │                                         │
  ┌────────┐         │  aws-vpn-gw.tf ──── AWS VPN Gateway     │
  │ Add    │────────▶│  azure-vpn-gw.tf ── Azure VPN Gateway   │
  │ conn   │  copy   │  gcp-vpn-gw.tf ──── GCP HA VPN Gateway  │
  │ files  │  files  │                                         │
  └────────┘         │  conn-aws-azure-main.tf ── conn module  │
                     │  conn-azure-gcp-main.tf ── conn module  │
  ┌────────┐         │  conn-aws-gcp-main.tf ─── conn module   │
  │ Remove │────────▶│                                         │
  │ conn   │targeted │  modules/conn-aws-azure/                │
  │        │destroy  │  modules/conn-azure-gcp/                │
  │        │→ delete │  modules/conn-aws-gcp/                  │
  └────────┘         │                                         │
                     │  terraform.tfstate ← 단일 state         │
                     └─────────────────────────────────────────┘
```

### 2.2. 기술적 과제 해결

#### 과제 1: Gateway Output에서 Connection 참조 제거

**문제**: 현재 `aws-output.tf`에서 connection 모듈을 직접 참조합니다:

```hcl
# templates/vpn/site-to-site/aws/aws-output.tf (현재)
output "aws_vpn_info" {
  value = {
    aws = merge(
      { vpn_gateway = { ... } },
      try(module.conn_aws_azure.aws_vpn_conn_info, {})  # ← 교차 참조!
    )
  }
}
```

이 구조에서 `conn-aws-azure` 모듈 호출을 제거하면, `module.conn_aws_azure`가 구성에서 사라지면서 OpenTofu 파싱 에러가 발생합니다. (`try()`는 런타임 에러만 처리하며, 구성 수준의 모듈 참조 부재는 처리 불가)

**해결**: Gateway output은 gateway 정보만 출력하도록 분리합니다:

```hcl
# aws/aws-output.tf (변경 후)
output "aws_vpn_gateway_info" {    # ← 이름도 gateway_info로 변경
  description = "AWS VPN Gateway details only"
  value = {
    vpn_gateway = {
      resource_type = "aws_vpn_gateway"
      name          = try(aws_vpn_gateway.vpn_gw.tags.Name, "")
      id            = try(aws_vpn_gateway.vpn_gw.id, "")
      vpc_id        = try(aws_vpn_gateway.vpn_gw.vpc_id, "")
    }
  }
}
# ↑ connection module 참조 없음 → connection 추가/제거에 영향 없음
```

> **참고**: 현재 `azure-output.tf`는 connection 참조가 주석 처리되어 있고, `gcp-output.tf`는 이미 `gcp_vpn_gateway_info`로 분리되어 있습니다. AWS output만 실제 수정이 필요합니다.

#### 과제 2: Connection Output 이름 충돌 해결

**문제**: 현재 conn output 파일의 output 이름이 CSP별로 중복됩니다:

```hcl
# conn-aws-azure/conn-aws-azure-output.tf
output "azure_vpn_conn_info" { ... }

# conn-azure-gcp/conn-azure-gcp-output.tf
output "azure_vpn_conn_info" { ... }  # ← 이름 충돌!
```

AWS+Azure+GCP를 동시에 구성하면 `azure_vpn_conn_info`가 두 번 정의되어 OpenTofu 에러 발생

**해결**: 각 pair별 고유 output 이름을 사용합니다:

```hcl
# conn-aws-azure/conn-aws-azure-output.tf (변경 후)
output "conn_aws_azure_info" {       # ← pair 고유 이름
  description = "AWS-Azure VPN connection details"
  value = {
    aws   = try(module.conn_aws_azure.aws_vpn_conn_info, {})
    azure = try(module.conn_aws_azure.azure_vpn_conn_info, {})
  }
}

# conn-azure-gcp/conn-azure-gcp-output.tf (변경 후)
output "conn_azure_gcp_info" {       # ← pair 고유 이름, 충돌 없음
  description = "Azure-GCP VPN connection details"
  value = {
    azure = try(module.conn_azure_gcp.azure_vpn_conn_info, {})
    gcp   = try(module.conn_azure_gcp.gcp_vpn_conn_info, {})
  }
}
```

#### 과제 3: Provider 구성 생명주기 관리

CSP를 완전히 제거할 때, provider 구성 파일의 순서 관리가 필요합니다.

**Targeted Destroy를 활용한 안전한 제거 순서**:

```
Connection 리소스 파기:
  1. tofu destroy -target=module.conn_aws_azure -auto-approve
  2. 성공 시: conn-aws-azure-main.tf, conn-aws-azure-output.tf 삭제
  3. tofu init (모듈 참조 정리)

CSP 완전 제거 (선택):
  4. tofu destroy -target=aws_vpn_gateway.vpn_gw -auto-approve
     (aws_vpn_gateway_route_propagation.main은 VPN GW에 의존하므로 자동 삭제)
  5. 성공 시: aws-vpn-gw.tf, aws-output.tf 삭제
  6. aws-provider.tf 삭제 (리소스 없으므로 안전)
  7. tofu init
```

**핵심**: Provider 파일은 반드시 해당 CSP의 모든 리소스가 파기된 후에 제거해야 합니다.

#### 과제 4: Gateway Output 패턴 표준화

**문제**: 현재 CSP별 gateway output 패턴이 불일치합니다:

| CSP     | 현재 Output 이름                                                 | 출력 구조                         |
| ------- | ---------------------------------------------------------------- | --------------------------------- |
| AWS     | `aws_vpn_info` (conn 참조 포함)                                  | 통합 object (gateway + conn 혼재) |
| Azure   | `azure_vpn_info`                                                 | 통합 object (conn 참조 주석 처리) |
| GCP     | `gcp_vpn_gateway_info`, `gcp_router_info`                        | 분리된 output (이미 올바름)       |
| Alibaba | `alibaba_vpn_gateway_id`, `alibaba_vpn_gateway_internet_ip`, ... | **개별 output** (비표준)          |

**해결**: 모든 CSP의 gateway output을 `{csp}_vpn_gateway_info` 형식으로 표준화합니다:

```hcl
# alibaba/alibaba-output.tf (변경 후 ← 현재 개별 output을 통합)
output "alibaba_vpn_gateway_info" {
  description = "Alibaba VPN Gateway details"
  value = {
    vpn_gateway = {
      resource_type            = "alicloud_vpn_gateway"
      id                       = try(alicloud_vpn_gateway.vpn_gw.id, "")
      internet_ip              = try(alicloud_vpn_gateway.vpn_gw.internet_ip, "")
      vpc_id                   = try(data.alicloud_vpcs.existing.vpcs[0].id, "")
      region                   = var.vpn_config.alibaba.region
      bgp_asn                  = var.vpn_config.alibaba.bgp_asn
    }
  }
}
```

Handler에서의 output 수집 패턴도 이에 맞춰 통일합니다:

```go
// gateway info: "{csp}_vpn_gateway_info" (모든 CSP 공통)
for _, provider := range providers {
    targetObject := fmt.Sprintf("%s_vpn_gateway_info", provider)
    gatewayInfo, _ := terrarium.Output(trId, reqId, targetObject, "-json")
    mergeResourceInfo(result, gatewayInfo)
}

// connection info: "conn_{pair}_info" (pair 고유)
for i := 0; i < len(providers); i++ {
    for j := i + 1; j < len(providers); j++ {
        pair := fmt.Sprintf("%s_%s", providers[i], providers[j])
        targetObject := fmt.Sprintf("conn_%s_info", pair)
        connInfo, err := terrarium.Output(trId, reqId, targetObject, "-json")
        if err != nil {
            continue  // 해당 pair connection이 없으면 skip
        }
        mergeResourceInfo(result, connInfo)
    }
}
```

### 2.3. Connection 제거 전략: Targeted Destroy

Connection 제거 시 `.tf` 파일을 먼저 삭제하면, apply 실패 시 "orphaned resource" 문제가 발생합니다:

```
위험한 흐름 (파일 삭제 → apply):
  conn-aws-gcp-main.tf 삭제 → tofu apply → GCP 터널 파기 실패 ❌
  → .tf 파일: 없음 (이미 삭제됨)
  → State: GCP 터널 아직 존재
  → 결과: 관리 코드 없는 "orphaned" 리소스 발생
```

**해결: Targeted Destroy** — `.tf` 파일을 먼저 삭제하지 않고, `tofu destroy -target`으로 특정 모듈의 리소스만 먼저 파기한 후 성공 시에만 `.tf` 파일을 삭제합니다.

```bash
# 특정 connection module만 destroy
tofu destroy -target=module.conn_aws_gcp -auto-approve
```

#### 워크플로우

```
안전한 흐름 (destroy → 파일 삭제):
  1. tofu destroy -target=module.conn_aws_gcp -auto-approve
     → 성공 ✅: conn-aws-gcp-main.tf, conn-aws-gcp-output.tf 삭제 → tofu init
     → 실패 ❌: 파일이 그대로 있으므로 아무 조치 불필요. 재시도 가능.
```

#### 장점

| 항목          | 파일 삭제 후 apply                       | Targeted Destroy (-target 방식)       |
| ------------- | ---------------------------------------- | ------------------------------------- |
| 파일 상태     | 삭제됨 (복구 불가)                       | **파일을 건드리지 않음**              |
| 실패 시 복구  | orphaned resource → 수동 복구            | **복구 불필요** (재시도만)            |
| 의존성 그래프 | 모듈 제거 상태에서 불완전 가능           | **완전한 상태에서 destroy**           |
| 구현 복잡도   | 별도 복구 로직 필요                      | **단순** (destroy → success → delete) |
| state 일관성  | apply 실패 시 state와 config 불일치 가능 | **항상 일관**                         |

#### Handler pseudocode

```go
func removeConnection(trId, pair, reqId string) error {
    workingDir := getWorkingDir(trId)

    // Step 1: Targeted destroy (파일은 그대로 둔 채 리소스만 파기)
    targetModule := fmt.Sprintf("module.conn_%s", strings.ReplaceAll(pair, "-", "_"))
    _, err := terrarium.DestroyTarget(trId, reqId, targetModule)
    if err != nil {
        // .tf 파일이 그대로 있으므로 복구 불필요
        // 재시도만 하면 됨
        return fmt.Errorf("failed to destroy connection %s, retry possible: %w", pair, err)
    }

    // Step 2: Destroy 성공 → .tf 파일 삭제
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-main.tf"))
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-output.tf"))

    // Step 3: Re-init (모듈 참조 정리)
    terrarium.Init(trId, reqId)

    return nil
}
```

#### terrarium 패키지에 추가할 함수

```go
// DestroyTarget destroys specific resources by target
func DestroyTarget(trId, reqId string, targets ...string) (string, error) {
    workingDir, err := GetTerrariumEnvPath(trId)
    if err != nil {
        return "", err
    }

    tfcli := tfclient.NewClient(trId, reqId)
    tfcli.SetChdir(workingDir)
    tfcli.Destroy()

    // -target 옵션 추가
    for _, target := range targets {
        tfcli.SetArg(fmt.Sprintf("-target=%s", target))
    }

    ret, err := tfcli.Auto().Exec()
    if err != nil {
        return "", err
    }
    return ret, nil
}
```

> **참고**: 현재 `tfclient`에 `-target` 전용 메서드는 없지만, 기존 `SetArg()` 메서드(client.go line 431)로 `-target=module.conn_aws_gcp`를 전달할 수 있습니다. 향후 `Target(resource string)` 편의 메서드를 추가하면 더 명확해집니다.

#### 다양한 Connection 제거 시나리오

**Scenario 1: 단일 Connection 제거**

```bash
# AWS-GCP 연결만 제거
tofu destroy -target=module.conn_aws_gcp -auto-approve
# 성공 → conn-aws-gcp-main.tf, conn-aws-gcp-output.tf 삭제
```

**Scenario 2: 여러 Connection 동시 제거**

```bash
# AWS-GCP, AWS-Azure 연결 동시 제거
tofu destroy \
  -target=module.conn_aws_gcp \
  -target=module.conn_aws_azure \
  -auto-approve
# 성공 → 해당 conn 파일들 삭제
```

**Scenario 3: 특정 CSP의 모든 Connection + Gateway 제거**

```bash
# AWS 관련 모든 것을 제거 (connection → gateway 순서)
# Step 1: AWS 관련 connection 모듈 먼저 destroy
tofu destroy \
  -target=module.conn_aws_azure \
  -target=module.conn_aws_gcp \
  -auto-approve
# 성공 → conn-aws-azure/gcp 파일 삭제 + tofu init

# Step 2: AWS gateway 리소스 destroy
tofu destroy -target=aws_vpn_gateway.vpn_gw -auto-approve
# (aws_vpn_gateway_route_propagation.main은 VPN GW에 의존하므로 자동 삭제)
# 성공 → aws-vpn-gw.tf, aws-output.tf, aws-provider.tf 삭제 + tofu init
```

#### 부분 실패 시 복구 전략

Targeted Destroy도 부분 실패가 발생할 수 있습니다. 그러나 `.tf` 파일이 존재하므로 복구가 훨씬 용이합니다:

| 상황             | 파일 삭제 후 apply                       | Targeted Destroy              |
| ---------------- | ---------------------------------------- | ----------------------------- |
| 부분 실패        | .tf 없음, state에 리소스 남음 → orphaned | **.tf 있음, 재시도 가능**     |
| CSP 일시 장애    | 수동 복구 필요                           | **재시도만 하면 됨**          |
| 의존성 순서 문제 | 의존성 그래프 불완전                     | **완전한 그래프로 순서 보장** |
| state 불일치     | refresh + 수동 조치                      | **refresh만으로 해결**        |

```
1차 복구: tofu destroy -target=module.conn_xxx 재실행 (자동)
2차 복구: tofu refresh → tofu destroy -target=... 재실행 (자동)
3차 복구: tofu state rm + CSP 콘솔에서 수동 삭제 (반자동, 최후 수단)
```

### 2.4. 전체 Destroy 전략: Phased Destroy

#### 문제 정의

Option D에서 Gateway와 Connection은 동일 terrarium 내에서 **별도의 생애주기**로 관리됩니다. 개별 Connection 제거는 Targeted Destroy로 안전하게 처리되지만, **전체 인프라를 한 번에 파기**(`DELETE /tr/{trId}/vpn/site-to-site/actions/destroy`)할 때 종속성 이슈가 발생할 수 있습니다.

Connection 모듈은 Gateway 리소스를 직접 참조합니다:

```hcl
# conn-aws-azure-main.tf
module "conn_aws_azure" {
  aws_vpn_gateway_id               = aws_vpn_gateway.vpn_gw.id                  # ← AWS GW 참조
  azure_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id   # ← Azure GW 참조
}
```

OpenTofu는 기본적으로 의존성 그래프의 역순으로 destroy를 수행하므로 Connection → Gateway 순서를 지켜야 합니다. 그러나 다음 상황에서 문제가 발생합니다:

| 상황                         | 문제                                                                                     | 발생 조건           |
| ---------------------------- | ---------------------------------------------------------------------------------------- | ------------------- |
| **CSP API 순서 경합**        | CSP가 내부적으로 추가 의존성을 가짐 (e.g. AWS VPN Connection 삭제 완료 전 VGW 삭제 시도) | CSP API 비동기 처리 |
| **병렬 삭제 race condition** | OpenTofu가 독립적인 connection 모듈을 병렬로 삭제하면서 공유 gateway에 동시 접근         | 3+ CSP 구성         |
| **부분 실패 cascade**        | 하나의 connection destroy 실패 → 해당 gateway destroy 불가 → 다른 connection에도 영향    | CSP 일시 장애       |

```
위험 시나리오 (3-CSP 구성: AWS + Azure + GCP):

  tofu destroy (전체)
    ├── module.conn_aws_azure destroy ← 성공 ✅
    ├── module.conn_azure_gcp destroy ← GCP tunnel 삭제 실패 ❌
    ├── module.conn_aws_gcp   destroy ← 성공 ✅
    │
    ├── aws_vpn_gateway.vpn_gw destroy ← 성공 ✅ (AWS connection 모두 삭제됨)
    ├── azurerm_virtual_network_gateway.vpn_gw destroy ← 실패 ❌
    │     (conn_azure_gcp의 Azure 리소스가 아직 남아있어 삭제 불가)
    └── google_compute_ha_vpn_gateway.vpn_gw destroy ← 실패 ❌
          (conn_azure_gcp의 GCP 터널이 아직 남아있어 삭제 불가)

  결과: AWS 리소스만 삭제, Azure/GCP는 부분적 상태로 남음
```

#### 해결: Phased Destroy

전체 destroy를 단일 `tofu destroy`가 아닌, **Connection → Gateway** 순서로 단계적으로 실행합니다.

```
Phased Destroy 흐름:

  Phase 1: 모든 Connection 모듈을 Targeted Destroy
    tofu destroy -target=module.conn_aws_azure -auto-approve
    tofu destroy -target=module.conn_azure_gcp -auto-approve
    tofu destroy -target=module.conn_aws_gcp   -auto-approve
    → 모든 connection 리소스 파기 완료

  Phase 2: 나머지 Gateway 리소스 전체 Destroy
    tofu destroy -auto-approve
    → Gateway, Route Propagation, Provider 리소스만 남아있으므로 안전하게 삭제

  Phase 3: 워크스페이스 정리
    .tf 파일 및 state 파일 삭제 (EmptyOut)
```

#### Phased Destroy의 장점

| 항목           | 단일 tofu destroy                         | Phased Destroy                               |
| -------------- | ----------------------------------------- | -------------------------------------------- |
| 삭제 순서 제어 | OpenTofu 의존성 그래프에 의존             | **명시적 순서 보장**                         |
| 부분 실패 대응 | 전체 실패, 재시도 시 꼬인 state 가능      | **Phase별 독립적 재시도**                    |
| 병렬 삭제 경합 | OpenTofu가 자체 판단으로 병렬화           | **순차 실행으로 경합 방지**                  |
| 에러 진단      | 어떤 리소스에서 실패했는지 파악 어려움    | **Phase/Connection별 에러 추적 가능**        |
| Gateway 보호   | Connection 실패 시 Gateway도 cascade 실패 | **Connection 전부 성공 후에만 Gateway 삭제** |

#### Handler pseudocode: destroySiteToSiteVpn 개선

```go
func destroySiteToSiteVpn(trId, reqId string) (model.Response, error) {

    // ──────────────────────────────────────────────
    // Phase 1: 모든 Connection 모듈을 Targeted Destroy
    // ──────────────────────────────────────────────
    connPairs := getActiveConnectionPairs(trId) // workspace의 conn-*.tf 파일 스캔
    for _, pair := range connPairs {
        targetModule := fmt.Sprintf("module.conn_%s", strings.ReplaceAll(pair, "-", "_"))
        _, err := terrarium.DestroyTarget(trId, reqId, targetModule)
        if err != nil {
            log.Error().Err(err).Msgf("Phase 1: failed to destroy connection %s", pair)
            // 실패한 connection이 있어도 나머지는 계속 시도
            // (독립적인 connection은 서로 영향 없음)
            continue
        }
        // 성공한 connection의 .tf 파일 삭제
        removeConnFiles(trId, pair)
    }

    // Phase 1 실패 체크: 아직 남은 connection이 있으면 Gateway 삭제 불가
    remainingConns := getActiveConnectionPairs(trId)
    if len(remainingConns) > 0 {
        return emptyRes, fmt.Errorf(
            "Phase 1 incomplete: %d connections remain (%v), retry needed before gateway destroy",
            len(remainingConns), remainingConns,
        )
    }

    // ──────────────────────────────────────────────
    // Phase 2: 나머지 Gateway 리소스 전체 Destroy
    // ──────────────────────────────────────────────
    ret, err := terrarium.Destroy(trId, reqId)
    if err != nil {
        log.Error().Err(err).Msg("Phase 2: failed to destroy gateways")
        return emptyRes, err
    }

    return model.Response{Success: true, Message: ret}, nil
}
```

#### getActiveConnectionPairs 유틸리티

```go
// getActiveConnectionPairs scans the workspace for active connection files
func getActiveConnectionPairs(trId string) []string {
    workingDir, _ := terrarium.GetTerrariumEnvPath(trId)
    entries, _ := os.ReadDir(workingDir)

    var pairs []string
    for _, entry := range entries {
        name := entry.Name()
        // conn-aws-azure-main.tf → "aws-azure"
        if strings.HasPrefix(name, "conn-") && strings.HasSuffix(name, "-main.tf") {
            pair := strings.TrimPrefix(name, "conn-")
            pair = strings.TrimSuffix(pair, "-main.tf")
            pairs = append(pairs, pair)
        }
    }
    return pairs
}
```

#### Phase 1 실패 시 재시도 전략

Phase 1에서 일부 connection destroy가 실패하면 Phase 3으로 진행하지 않습니다. 이는 gateway를 보호하기 위해 의도적입니다:

```
Phase 1 부분 실패 시:
  conn_aws_azure  destroy → 성공 ✅ → .tf 삭제
  conn_azure_gcp  destroy → 실패 ❌ → .tf 유지 (재시도 가능)
  conn_aws_gcp    destroy → 성공 ✅ → .tf 삭제

  → Phase 2/3 진행 차단
  → 에러 응답: "1 connection(s) remain, retry needed"
  → 사용자가 재시도하면 conn_azure_gcp만 다시 시도
  → 성공 시 Phase 2/3 진행
```

이 접근법의 핵심 원칙: **Connection이 모두 파기되기 전에는 Gateway를 절대 삭제하지 않는다.**

#### 전체 destroy API에서의 Phased Destroy 호출

```
DELETE /tr/{trId}/vpn/site-to-site/actions/destroy
→ 내부 동작:
  Phase 1: 활성 connection pair 목록 조회 → 각각 Targeted Destroy
  Phase 2: tofu destroy (gateway + route propagation + 나머지)
  → 성공 시: EmptyOut으로 workspace 정리
```

#### 기존 코드와의 호환성

현재 `destroySiteToSiteVpn` 핸들러에서 이미 수행하는 작업과 비교:

```go
// 현재 (2-CSP only)
terrarium.Destroy(trId, reqId)  // 전체 destroy

// 변경 후 (N-CSP, Phased Destroy)
Phase 1: for each conn pair → DestroyTarget(targetModule)  // 신규
Phase 2: Destroy(trId, reqId)                               // 기존 유지
```

변경 포인트는 Phase 1의 추가뿐이며, Phase 2는 기존 `Destroy` 로직을 그대로 활용합니다.

### 2.5. Working Directory 구조 (실행 시)

`CopyFiles`는 파일을 flat하게 복사하고, `CopyDir`는 디렉토리를 재귀적으로 복사합니다. 실제 working directory는 다음과 같습니다:

```
.terrarium/{trId}/vpn/site-to-site/
├── terraform.tf                    # OpenTofu/provider version constraints
├── variables.tf                    # Variable definitions
├── terraform.tfvars.json           # Variable values
│
├── aws-provider.tf                 # AWS provider config (from aws/)
├── aws-vpn-gw.tf                   # AWS VPN Gateway (from aws/)
├── aws-vpn-gateway-info-output.tf  # AWS gateway info only (from aws/)
│
├── azure-provider.tf               # Azure provider config (from azure/)
├── azure-vpn-gw.tf                 # Azure VPN Gateway (from azure/)
├── azure-vpn-gateway-info-output.tf # Azure gateway info only (from azure/)
│
├── gcp-provider.tf                 # GCP provider config (from gcp/)
├── gcp-vpn-gw.tf                   # GCP HA VPN Gateway (from gcp/)
├── gcp-vpn-gateway-info-output.tf  # GCP gateway info only (from gcp/)
│
├── conn-aws-azure-main.tf          # conn module invocation (from conn-aws-azure/)
├── conn-aws-azure-output.tf        # conn-specific output (from conn-aws-azure/)
│
├── conn-azure-gcp-main.tf          # conn module invocation (from conn-azure-gcp/)
├── conn-azure-gcp-output.tf        # conn-specific output (from conn-azure-gcp/)
│
├── conn-aws-gcp-main.tf            # conn module invocation (from conn-aws-gcp/)
├── conn-aws-gcp-output.tf          # conn-specific output (from conn-aws-gcp/)
│
└── modules/                        # Module source code (CopyDir로 재귀 복사)
    ├── conn-aws-azure/
    ├── conn-azure-gcp/
    └── conn-aws-gcp/
```

### 2.6. API 설계

#### 설계 원칙

- **일괄 생성/삭제를 중점 기능으로 제공** (Primary API)
- 점진적 Connection 추가/제거는 선택적 확장 기능 (Optional API)
- 기존 site-to-site API 패턴과 호환

#### Primary API: Full-Mesh 일괄 생성/삭제

사용자가 N개 CSP를 지정하면, 모든 Gateway + 모든 Connection ($\binom{N}{2}$ pair)을 일괄 생성/삭제합니다:

```
# 일괄 생성 (단계별 실행)
POST   /tr/{trId}/vpn/site-to-site/actions/init      # N-CSP 초기 구성 (2+ CSPs)
POST   /tr/{trId}/vpn/site-to-site/actions/plan       # Plan
POST   /tr/{trId}/vpn/site-to-site/actions/apply      # Apply
GET    /tr/{trId}/vpn/site-to-site/actions/output      # 정보 조회

# 일괄 삭제 (Phased Destroy: Connection → Gateway 순서)
DELETE /tr/{trId}/vpn/site-to-site/actions/destroy     # 전체 파기
DELETE /tr/{trId}/vpn/site-to-site/actions/emptyout    # 워크스페이스 정리
```

cb-tumblebug 친화적 고수준 API:

```
# 전체 VPN 생성 (내부적으로 init → plan → apply 일괄 실행)
POST /tr/{trId}/vpn/site-to-site
Body: { "vpn_config": { "aws": {...}, "azure": {...}, "gcp": {...} } }

# VPN 조회
GET /tr/{trId}/vpn/site-to-site?detail=refined

# 전체 VPN 삭제 (내부적으로 Phased Destroy → EmptyOut 실행)
DELETE /tr/{trId}/vpn/site-to-site
```

#### Optional API: 점진적 Connection 관리

기존 VPN 환경에 CSP를 추가하거나, 특정 Connection만 제거하는 확장 기능입니다:

```
# Connection 추가 (새 CSP와 기존 CSP들 간의 모든 pair 생성)
POST   /tr/{trId}/vpn/site-to-site/connections/actions/add-and-init
       # Body: { "add_csp": { "gcp": { region: "...", ... } } }
POST   /tr/{trId}/vpn/site-to-site/connections/actions/plan
POST   /tr/{trId}/vpn/site-to-site/connections/actions/apply

# Connection 제거 (Targeted Destroy)
DELETE /tr/{trId}/vpn/site-to-site/connections/{pair}
       # 주의: Full-Mesh 무결성이 깨질 수 있음 (Transit Routing 미지원)
```

> **주의**: Connection을 개별 제거하면 Full-Mesh가 깨져 일부 CSP 간 통신이 불가능해질 수 있습니다 (§2.11 참조). 개별 Connection 제거보다는 CSP 단위 제거를 권장합니다.

#### CSP 제약사항 기반 Validation

API level에서 CSP별 제약사항을 사전 검증합니다:

| CSP         | 제약사항                     | 제한                          | Full-Mesh 영향                                     |
| ----------- | ---------------------------- | ----------------------------- | -------------------------------------------------- |
| **AWS**     | VGW당 최대 VPN Connection 수 | 10개                          | CSP당 2 Connection × 최대 5개 원격 CSP = 10 (한계) |
| **Azure**   | APIPA 주소 범위              | 169.254.21.0 ~ 169.254.22.255 | CSP별 CIDR 할당으로 6개 CSP 지원 가능              |
| **Azure**   | VPN GW당 최대 Connection 수  | SKU별 상이 (VpnGw1: 30개)     | 충분                                               |
| **GCP**     | HA VPN Gateway 인터페이스    | 2개 고정                      | External GW 설정으로 대응                          |
| **Alibaba** | VPN Gateway 대역폭           | 최소 10Mbps                   | 대역폭 공유                                        |

```go
// Validation pseudocode
func validateCSPConstraints(csps []string) error {
    // AWS VGW: 최대 10 VPN connections
    // CSP당 2 connections 가정 → 최대 5개 원격 CSP 연결 가능
    if containsAWS(csps) && len(csps)-1 > 5 {
        return fmt.Errorf("AWS VGW supports max 10 connections (5 remote CSPs × 2), requested: %d", len(csps)-1)
    }
    return nil
}
```

### 2.7. 사용자 워크플로우

#### Scenario 1: 최초 3-CSP 구성 (AWS + Azure + GCP)

```
Step 1: Init (모든 gateway + connection 한 번에)
  POST /tr/tr01/vpn/site-to-site/actions/init
  Body: {
    "vpn_config": {
      "terrarium_id": "tr01",
      "aws":   { "region": "ap-northeast-2", "vpc_id": "...", ... },
      "azure": { "region": "koreacentral", ... },
      "gcp":   { "region": "asia-northeast3", ... }
    }
  }
  → 3 CSP gateway + 3 conn pair (aws-azure, aws-gcp, azure-gcp)

Step 2: Plan → Apply
  POST /tr/tr01/vpn/site-to-site/actions/plan
  POST /tr/tr01/vpn/site-to-site/actions/apply
```

#### Scenario 2: 기존 환경에 Alibaba 추가

```
Step 1: Add connection
  POST /tr/tr01/vpn/site-to-site/connections/actions/add-and-init
  Body: {
    "add_csp": {
      "alibaba": { "region": "ap-northeast-2", ... }
    }
  }
  → alibaba gateway 파일 복사
  → conn-alibaba-aws, conn-alibaba-azure, conn-alibaba-gcp 파일 복사
  → tfvars 업데이트
  → tofu init

Step 2: Plan → Apply
  POST /tr/tr01/vpn/site-to-site/connections/actions/plan
  POST /tr/tr01/vpn/site-to-site/connections/actions/apply
  → Alibaba VPN Gateway 생성 + 3개 새 connection 생성
  → 기존 AWS, Azure, GCP gateway와 connection은 변경 없음
```

#### Scenario 3: AWS-GCP 연결만 제거

```
Step 1: Targeted Destroy로 connection 제거
  DELETE /tr/tr01/vpn/site-to-site/connections/aws-gcp
  → 내부 동작:
    1. tofu destroy -target=module.conn_aws_gcp -auto-approve
    2. 성공 → conn-aws-gcp-main.tf, conn-aws-gcp-output.tf 삭제
    3. tofu init (module 정리)
  → AWS gateway, GCP gateway, 다른 connection은 유지됨
```

#### Scenario 4: AWS를 완전히 제거 (gateway + 모든 AWS connection)

```
Step 1: AWS 관련 모든 connection의 Targeted Destroy
  DELETE /tr/tr01/vpn/site-to-site/connections/aws-azure
  DELETE /tr/tr01/vpn/site-to-site/connections/aws-gcp
  → 내부 동작:
    각각 tofu destroy -target=module.conn_aws_azure, conn_aws_gcp
    → 성공 → conn 파일 삭제 → tofu init

Step 2: AWS gateway 제거
  # 또는 일괄 제거 API:
  # DELETE /tr/tr01/vpn/site-to-site/csp/aws
  → 내부 동작:
    tofu destroy -target=aws_vpn_gateway.vpn_gw -auto-approve
    (aws_vpn_gateway_route_propagation.main은 VPN GW에 의존하므로 자동 삭제)
    → 성공 → aws-vpn-gw.tf, aws-output.tf, aws-provider.tf 삭제
    → tofu init

Step 3: 결과 확인
  → Azure, GCP gateway + azure-gcp connection은 유지됨
```

### 2.8. Handler 변경 사항

#### 2.8.1. initSiteToSiteVpn 변경

```go
// 변경: 2개 이상의 CSP 허용 (현재: len(providers) != 2)
if len(providers) < 2 {
    err := fmt.Errorf("site-to-site VPN requires at least 2 CSPs, got %d", len(providers))
    ...
}

// 변경: 모든 CSP pair에 대해 conn 파일 복사
// (현재: 단일 pair만 처리 — providerPair := fmt.Sprintf("%s-%s", providers[0], providers[1]))
for i := 0; i < len(providers); i++ {
    for j := i + 1; j < len(providers); j++ {
        pair := fmt.Sprintf("%s-%s", providers[i], providers[j])
        connDir := projectRoot + "/templates/" + enrichments + "/conn-" + pair
        err = tfutil.CopyFiles(connDir, workingDir)
        if err != nil {
            log.Warn().Err(err).Msgf("conn template for pair %s not found", pair)
        }
    }
}
```

#### 2.8.2. 신규 addConnectionHandler

```go
func addConnectionInit(c echo.Context) (model.Response, error) {
    trId := c.Param("trId")

    // 1. 현재 terrarium 정보 로드
    trInfo, exists, err := terrarium.GetInfo(trId)

    // 2. 새 CSP 설정 받기
    req := new(model.AddConnectionRequest)
    c.Bind(req)
    newCsp := req.AddCsp  // e.g., "gcp"

    // 3. 기존 providers 목록에 새 CSP 추가
    existingProviders := trInfo.Providers
    allProviders := append(existingProviders, newCsp)
    sort.Strings(allProviders)

    // 4. 새 CSP gateway 파일 복사 (CopyFiles — flat)
    cspDir := projectRoot + "/templates/" + enrichments + "/" + newCsp
    tfutil.CopyFiles(cspDir, workingDir)

    // 5. 새 CSP × 기존 CSP 모든 pair에 대해 conn 파일 복사 (CopyFiles — flat)
    for _, existing := range existingProviders {
        pair := sortedPair(existing, newCsp) // 알파벳 순 정렬
        connDir := projectRoot + "/templates/" + enrichments + "/conn-" + pair
        tfutil.CopyFiles(connDir, workingDir)
    }

    // 6. 새 모듈 소스 복사 (CopyDir — 재귀)
    srcModuleDir := templateTfsPath + "/modules"
    dstModuleDir := workingDir + "/modules"
    tfutil.CopyDir(srcModuleDir, dstModuleDir)

    // 7. tfvars 업데이트 (기존 config에 새 CSP config merge)
    existingTfVars := loadTfVars(workingDir)
    existingTfVars.VpnConfig.Gcp = req.GcpConfig  // 예시
    terrarium.SaveTfVars(trId, enrichments, existingTfVars)

    // 8. terrarium info 업데이트
    trInfo.Providers = allProviders
    terrarium.UpdateInfo(trInfo)

    // 9. tofu init
    ret, err := terrarium.Init(trId, reqId)
    // ...
}
```

#### 2.8.3. 신규 removeConnectionHandler (Targeted Destroy 방식)

```go
func removeConnection(c echo.Context) (model.Response, error) {
    trId := c.Param("trId")
    pair := c.Param("pair")  // e.g., "aws-gcp"
    reqId := c.Response().Header().Get("X-Request-Id")

    workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments

    // Step 1: Targeted Destroy (파일은 그대로 둔 채 리소스만 파기)
    targetModule := fmt.Sprintf("module.conn_%s", strings.ReplaceAll(pair, "-", "_"))
    _, err := terrarium.DestroyTarget(trId, reqId, targetModule)
    if err != nil {
        // .tf 파일이 그대로 있으므로 복구 불필요, 재시도만 하면 됨
        log.Error().Err(err).Msgf("targeted destroy failed for %s, retry possible", pair)
        return model.Response{}, fmt.Errorf("failed to destroy connection %s: %w", pair, err)
    }

    // Step 2: Destroy 성공 → .tf 파일 삭제
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-main.tf"))
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-output.tf"))

    // Step 3: Re-init (모듈 참조 정리)
    terrarium.Init(trId, reqId)

    // Step 4: terrarium info 업데이트
    // (해당 pair 제거, CSP에 더 이상 connection이 없으면 providers에서도 제거 고려)

    return model.Response{Success: true}, nil
}
```

#### 2.8.4. outputSiteToSiteVpn 변경

```go
// 변경: Gateway info + Connection info를 분리 수집
// (현재: "{csp}_vpn_info" 단일 output 조회)

// Gateway info: "{csp}_vpn_gateway_info" output 조회
for _, provider := range providers {
    targetObject := fmt.Sprintf("%s_vpn_gateway_info", provider)
    gatewayInfo, _ := terrarium.Output(trId, reqId, targetObject, "-json")
    mergeResourceInfo(result, gatewayInfo)
}

// Connection info: "conn_{pair}_info" output 조회
for i := 0; i < len(providers); i++ {
    for j := i + 1; j < len(providers); j++ {
        pair := fmt.Sprintf("%s_%s", providers[i], providers[j])
        targetObject := fmt.Sprintf("conn_%s_info", pair)
        connInfo, err := terrarium.Output(trId, reqId, targetObject, "-json")
        if err != nil {
            continue  // 해당 pair connection이 없으면 skip
        }
        mergeResourceInfo(result, connInfo)
    }
}
```

### 2.9. Template 변경 사항 요약

| 파일                                | 현재                                          | 변경 후                                                 |
| ----------------------------------- | --------------------------------------------- | ------------------------------------------------------- |
| `aws/aws-output.tf`                 | `aws_vpn_info` (conn 참조 포함)               | `aws_vpn_gateway_info` (Gateway 정보만, conn 참조 제거) |
| `azure/azure-output.tf`             | `azure_vpn_info` (conn 참조 주석 처리됨)      | `azure_vpn_gateway_info` (Gateway 정보만, 이름 통일)    |
| `gcp/gcp-output.tf`                 | `gcp_vpn_gateway_info` (이미 올바름)          | 변경 없음                                               |
| `alibaba/alibaba-output.tf`         | 개별 output 5개 (`alibaba_vpn_gateway_id` 등) | `alibaba_vpn_gateway_info` (통합 output으로 표준화)     |
| `conn-{pair}/conn-{pair}-output.tf` | `{csp}_vpn_conn_info` (충돌 가능)             | `conn_{pair}_info` (pair 고유 이름)                     |

### 2.10. 장단점 분석

#### 장점

1. **단일 Terrarium**: Terrarium 간 state 교차 참조 없음. 같은 state 내에서 gateway를 직접 참조
2. **점진적 구성**: Connection을 하나씩 추가/제거 가능. 전체를 재구성할 필요 없음
3. **안전한 연결 제거**: Targeted Destroy(`tofu destroy -target`) → 성공 시에만 파일 삭제 → 실패 시 재시도 가능
4. **낮은 구현 복잡도**: 기존 site-to-site 코드를 확장. 새로운 아키텍처 패턴 불필요
5. **사용자 친화적**: 상위 시스템은 "CSP 추가" / "Connection 제거" API만 호출하면 됨
6. **기존 모듈 재활용**: conn-aws-azure, conn-azure-gcp, conn-alibaba-azure 모듈 그대로 사용

#### 단점

1. **State 크기**: N-CSP 전체가 하나의 state → CSP 수 증가 시 state가 커짐
2. **Apply 범위**: `tofu plan/apply`가 전체 state를 스캔 (단, 변경 없는 리소스는 no-change)
3. **부분 실패 복구**: 하나의 state에서 일부 CSP 리소스 생성 실패 시 복구 전략 필요
4. **AWS VGW 10 Connection 제한**: Full-mesh 6+ CSP 시 quota 초과 가능 (모든 방식의 공통 제약)

#### 위험도 분석

| 위험 요소       | 영향도 | 발생 가능성 | 완화 방안                                                              |
| --------------- | ------ | ----------- | ---------------------------------------------------------------------- |
| State 크기 증가 | 낮음   | 높음        | 7개 CSP 전부 연결해도 리소스 100~200개 수준, 관리 가능                 |
| Apply 시간 증가 | 중간   | 중간        | 변경 없는 리소스는 refresh만 수행, 실제 변경은 추가/제거 리소스만      |
| 부분 실패       | 높음   | 낮음        | 실패한 리소스는 다음 apply에서 재시도, state가 현재 상태를 정확히 반영 |
| Quota 초과      | 높음   | 낮음        | API에서 사전 검증, AWS VGW 최대 5 CSP 동시 연결 제한                   |

### 2.11. Transit Routing 분석

#### 문제 정의

MCI(Multi-Cloud Infrastructure) 내에서 Full-Mesh VPN을 구성할 때, **모든 CSP의 VM이 다른 모든 CSP의 VM과 통신할 수 있어야** 합니다. 이를 위해서는 각 CSP의 route table이 모든 원격 CSP의 CIDR에 대한 경로를 보유해야 합니다.

Transit routing이란, CSP A → CSP B → CSP C와 같이 **중간 CSP를 경유하여 트래픽을 전달**하는 것을 말합니다. 만약 CSP VPN Gateway가 transit routing을 지원하지 않으면, 모든 CSP pair가 직접 연결되어야 합니다.

#### CSP VPN Gateway의 라우팅 동작

코드베이스 분석 결과, **모든 CSP의 VPN Gateway는 다른 BGP peer에서 학습한 경로를 재광고(re-advertise)하지 않습니다:**

| CSP                  | 라우팅 방식                                            | 경로 광고 범위    | 재광고 여부 |
| -------------------- | ------------------------------------------------------ | ----------------- | ----------- |
| **AWS VGW**          | BGP + `aws_vpn_gateway_route_propagation`              | 자기 VPC CIDR만   | **NO**      |
| **Azure VPN GW**     | BGP (`enable_bgp = true`)                              | 자기 VNet CIDR만  | **NO**      |
| **GCP Cloud Router** | BGP (`advertised_groups = ["ALL_SUBNETS"]`)            | 자기 VPC subnet만 | **NO**      |
| **Alibaba**          | BGP (`enable_tunnels_bgp = true`) + 명시적 route entry | 자기 VPC CIDR만   | **NO**      |
| **Tencent**          | Static (`static_routes_only = true`)                   | 명시적 설정만     | 해당 없음   |
| **IBM**              | Static (`static_routes_only = true`)                   | 명시적 설정만     | 해당 없음   |

> **참고**: GCP Cloud Router의 `ALL_SUBNETS`는 "GCP VPC의 모든 subnet"을 의미하며, 다른 BGP peer에서 학습한 경로를 포함하지 않습니다.

#### 결론: Full-Mesh에서는 Transit Routing이 불필요

**Full-Mesh 토폴로지에서는 모든 CSP pair가 직접 터널을 가지므로, Transit Routing이 필요하지 않습니다.**

```
Full-Mesh 3-CSP (AWS, Azure, GCP) 예시:

AWS route table:                          ┌─────────┐
  10.2.0.0/16 → AWS-Azure 터널 (BGP)     │  AWS    │──── Azure
  10.3.0.0/16 → AWS-GCP 터널 (BGP)       │10.1.0.0 │
                                          └────┬────┘
Azure route table:                             │
  10.1.0.0/16 → Azure-AWS 터널 (BGP)          │
  10.3.0.0/16 → Azure-GCP 터널 (BGP)     ┌────┴────┐
                                          │  GCP    │
GCP route table:                          │10.3.0.0 │
  10.1.0.0/16 → GCP-AWS 터널 (BGP)       └─────────┘
  10.2.0.0/16 → GCP-Azure 터널 (BGP)

→ 모든 목적지가 직접 터널로 도달 가능 ✅
→ Transit routing 불필요 ✅
```

각 CSP는 N-1개의 직접 VPN connection을 통해 모든 원격 CSP의 CIDR을 학습합니다:

- **BGP CSP** (AWS, Azure, GCP, Alibaba): 직접 연결의 BGP 세션에서 자동 학습
- **Static CSP** (Tencent, IBM): 각 connection 모듈이 해당 pair의 CIDR 경로를 명시적으로 설정

#### Partial Mesh의 위험성

일부 pair만 연결하는 Partial Mesh에서는 Transit Routing이 필요하지만, CSP VPN Gateway가 이를 **지원하지 않으므로 통신 불가**:

```
Partial Mesh (AWS ↔ Azure ↔ GCP만, AWS ↔ GCP 직접 연결 없음):
  AWS VM → GCP VM: AWS → Azure 터널 → Azure VPN GW → ???
  → Azure VPN GW는 AWS→GCP 트래픽을 GCP 터널로 포워딩하지 않음 ❌
  → AWS→GCP 통신 불가 ❌
```

따라서 **Full-Mesh VPN은 반드시 Full-Mesh**여야 합니다. Option D의 설계는 N개 CSP 선택 시 모든 $\binom{N}{2}$ pair를 자동 생성하여 이를 보장합니다.

#### Static Routing CSP의 Connection 모듈 개발 시 고려사항

현재 `aws-to-site` 템플릿에서 Static routing CSP(Tencent, IBM)는 단일 원격 CIDR만 설정합니다:

```hcl
# 현재 (aws-to-site): 단일 원격 CIDR
resource "tencentcloud_vpn_gateway_route" "route" {
  destination_cidr_block = var.aws_vpc_cidr_block  # ← AWS CIDR 하나만
}
```

Full-Mesh `site-to-site` 모듈에서는 **각 connection 모듈이 해당 pair의 원격 CIDR만 담당**하면 되므로 구조적으로 동일합니다:

```hcl
# conn-aws-tencent 모듈: Tencent → AWS CIDR 경로 설정
resource "tencentcloud_vpn_gateway_route" "to_aws" {
  destination_cidr_block = var.aws_vpc_cidr  # AWS CIDR
}

# conn-azure-tencent 모듈: Tencent → Azure CIDR 경로 설정
resource "tencentcloud_vpn_gateway_route" "to_azure" {
  destination_cidr_block = var.azure_vnet_cidr  # Azure CIDR
}
# → N-1개 connection 모듈이 각각 1개 원격 CIDR 담당 → 전체적으로 모든 CIDR 커버
```

### 2.12. Dynamic/Static Routing 하이브리드 분석

#### 배경

7개 CSP 중 BGP를 지원하는 CSP(AWS, Azure, GCP, Alibaba)와 Static Routing만 지원하는 CSP(Tencent, IBM, DCS)가 혼재합니다. Full-Mesh를 구성하려면 **하나의 VPN Gateway에서 BGP Connection과 Static Connection이 동시에 공존**하는 하이브리드 구성이 필수적입니다.

#### CSP별 하이브리드 지원 여부

| CSP              | Routing 설정 레벨                                                              | 하이브리드 가능 | 근거                                                                                                                       |
| ---------------- | ------------------------------------------------------------------------------ | --------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **AWS VGW**      | Connection 레벨 (`static_routes_only` on `aws_vpn_connection`)                 | **가능**        | `aws-to-site` 템플릿에서 동일 VGW에 BGP(GCP, Azure, Alibaba) + Static(Tencent, IBM, DCS) 공존 확인                         |
| **Azure VPN GW** | Connection 레벨 (`enable_bgp` on `azurerm_virtual_network_gateway_connection`) | **가능**        | Gateway의 `enable_bgp = true`는 BGP "지원 가능" 선언이며, 각 Connection에서 `enable_bgp = false` 설정으로 Static 연결 가능 |
| **GCP HA VPN**   | Gateway/Router 레벨 (Cloud Router BGP 필수)                                    | **불가**        | GCP HA VPN은 모든 터널에 BGP 세션을 요구. Static-only Connection 개념 없음                                                 |
| **Alibaba**      | Connection 레벨 (`enable_tunnels_bgp` on `alicloud_vpn_connection`)            | **가능**        | Connection별 BGP/Static 독립 설정 가능                                                                                     |
| **Tencent**      | 고정 Static (`route_type = "StaticRoute"`)                                     | 해당 없음       | 항상 Static 측                                                                                                             |
| **IBM**          | 고정 Static (`mode = "route"`)                                                 | 해당 없음       | 항상 Static 측                                                                                                             |
| **DCS**          | 고정 Static (VPNaaS Endpoint Group)                                            | 해당 없음       | 항상 Static 측                                                                                                             |

> **핵심 발견**: AWS, Azure, Alibaba는 하이브리드 Routing을 지원하지만, **GCP는 불가능**합니다.

#### Full-Mesh Routing 매트릭스

| From \ To   | AWS    | Azure  | GCP      | Alibaba | Tencent  | IBM      | DCS      |
| ----------- | ------ | ------ | -------- | ------- | -------- | -------- | -------- |
| **AWS**     | -      | BGP    | BGP      | BGP     | Static   | Static   | Static   |
| **Azure**   | BGP    | -      | BGP      | BGP     | Static   | Static   | Static   |
| **GCP**     | BGP    | BGP    | -        | BGP     | **불가** | **불가** | **불가** |
| **Alibaba** | BGP    | BGP    | BGP      | -       | Static   | Static   | Static   |
| **Tencent** | Static | Static | **불가** | Static  | -        | Static   | Static   |
| **IBM**     | Static | Static | **불가** | Static  | Static   | -        | Static   |
| **DCS**     | Static | Static | **불가** | Static  | Static   | Static   | -        |

- **BGP**: 양측 모두 BGP 지원 → Dynamic Routing
- **Static**: 한쪽 이상이 BGP 미지원 → Static Routing (양쪽 모두 Static)
- **불가**: GCP HA VPN이 BGP를 강제하지만 상대가 BGP 미지원 → 직접 연결 불가

#### 결론

1. **하이브리드 Routing 자체는 실현 가능**: Routing 방식은 Connection 레벨에서 결정되므로, 동일 Gateway에서 BGP + Static 공존 가능 (AWS, Azure, Alibaba 검증 완료)
2. **GCP가 Full-Mesh의 병목**: GCP ↔ {Tencent, IBM, DCS} 3쌍이 직접 연결 불가
3. **7-CSP 완전 Full-Mesh 불가**: $\binom{7}{2} = 21$ 쌍 중 3쌍이 연결 불가
4. **가능한 구성 범위**:
   - BGP 4-CSP Full-Mesh (AWS, Azure, GCP, Alibaba): 완전 Full-Mesh 가능
   - GCP 제외 6-CSP Full-Mesh (AWS, Azure, Alibaba, Tencent, IBM, DCS): 하이브리드 Full-Mesh 가능
   - 7-CSP: GCP ↔ Static CSP 3쌍 제외한 Partial Mesh (18/21쌍)

---

## 3. 구현 로드맵

### 3.1. Phase 0: Template 리팩토링 + 나머지 CSP pair 모듈 개발 (단기, 1~2개월)

#### 0-1. Output 구조 리팩토링 (1주)

Option D의 핵심 선행 작업입니다:

1. **Gateway output 분리**: `aws-output.tf`에서 connection 모듈 참조를 제거하고 `aws_vpn_gateway_info`로 변경
2. **Gateway output 표준화**: `alibaba-output.tf`의 개별 output을 `alibaba_vpn_gateway_info`로 통합, `azure-output.tf`도 `azure_vpn_gateway_info`로 이름 변경
3. **Connection output 이름 고유화**: `conn-{pair}/conn-{pair}-output.tf`에서 `conn_{pair}_info` 형식으로 변경
4. **Handler 변경**: `outputSiteToSiteVpn()`에서 gateway info와 connection info를 별도로 수집하여 merge

#### 0-2. 나머지 Connection 모듈 개발 (1~2개월)

현재 구현된 pair (Azure 중심):

- ✅ conn-aws-azure
- ✅ conn-azure-gcp
- ✅ conn-alibaba-azure

개발 필요 pair (총 12개):

| #   | Pair                 | BGP       | 난이도 | 우선순위 |
| --- | -------------------- | --------- | ------ | -------- |
| 1   | conn-alibaba-aws     | ✅        | 중     | 높음     |
| 2   | conn-aws-gcp         | ✅        | 중     | 높음     |
| 3   | conn-aws-ibm         | ❌ Static | 중     | 중       |
| 4   | conn-aws-tencent     | ❌ Static | 중     | 중       |
| 5   | conn-alibaba-gcp     | ✅        | 중     | 중       |
| 6   | conn-azure-ibm       | ❌ Static | 중~높  | 중       |
| 7   | conn-azure-tencent   | ❌ Static | 중~높  | 중       |
| 8   | conn-alibaba-ibm     | ❌ Static | 중     | 낮음     |
| 9   | conn-alibaba-tencent | ❌ Static | 중     | 낮음     |
| 10  | conn-ibm-tencent     | ❌ Static | 중     | 낮음     |
| 11  | conn-alibaba-dcs     | ❌ Static | 중     | 낮음     |
| 12  | conn-aws-dcs         | ❌ Static | 중     | 낮음     |

구현 불가 pair (GCP ↔ Static CSP, §2.12 참조):

| #   | Pair             | 사유                                     |
| --- | ---------------- | ---------------------------------------- |
| -   | conn-gcp-ibm     | GCP HA VPN BGP 필수 ↔ IBM BGP 미지원     |
| -   | conn-gcp-tencent | GCP HA VPN BGP 필수 ↔ Tencent BGP 미지원 |
| -   | conn-dcs-gcp     | GCP HA VPN BGP 필수 ↔ DCS BGP 미지원     |

#### 개발 순서 권장

1. **conn-alibaba-aws, conn-aws-gcp** (BGP, 높은 우선순위)
2. **conn-aws-ibm, conn-aws-tencent** (Static routing, aws-to-site 모듈 참고)
3. **conn-alibaba-gcp** (BGP, alibaba-azure + azure-gcp 패턴 참고)
4. **conn-azure-ibm, conn-azure-tencent** (Azure APIPA + Static routing)
5. **나머지 pair** (사용 빈도에 따라)

#### 개발 프로세스 (pair당)

1. **examples/에 검증**: CSP 공식 문서의 VPN 연결 예제를 `examples/`에 작성하고 수동 테스트
2. **templates/ 모듈 개발**: 검증된 .tf를 `templates/vpn/site-to-site/modules/conn-{csp1}-{csp2}/`에 모듈화
3. **구현 레이어 개발**: `templates/vpn/site-to-site/conn-{csp1}-{csp2}/`에 모듈 호출 파일 작성
4. **output 표준화**: `conn_{pair}_info` 형식으로 output 작성

### 3.2. Phase 1: N-CSP 일괄 생성/삭제 API (단기, 0.5~1개월) ★ 핵심

Phase 0의 리팩토링과 모듈 준비 후, **Full-Mesh 일괄 생성/삭제를 중점 기능으로 구현**합니다:

1. **Handler 수정**: `len(providers) != 2` → `len(providers) < 2` (N-CSP 지원)
2. **Provider pair별 conn 복사 로직 추가** (N개 CSP의 모든 $\binom{N}{2}$ pair 자동 생성)
3. **Output 통합 수정**: `{csp}_vpn_gateway_info` + `conn_{pair}_info` 분리 수집 → merge
4. **Phased Destroy 구현**: Connection → Gateway 순서의 안전한 전체 삭제 (§2.4)
5. **CSP Validation 구현**: AWS VGW 10 Connection 제한 등 사전 검증 (§2.6)
6. **terrarium.DestroyTarget 함수 추가**: `-target` 기반 Phased Destroy Phase 1 지원

### 3.3. Phase 2: 안정화 및 점진적 Connection 관리 (중기, 1~2개월)

1. **점진적 Connection API (Optional)**: Connection 추가(`add-and-init`), 제거(Targeted Destroy) 엔드포인트
2. **CSP 단위 제거 API**: 특정 CSP와 관련된 모든 connection + gateway를 한 번에 Targeted Destroy
3. **상태 조회 고도화**: 활성 connection pair 목록, 각 pair별 상태 조회
4. **에러 복구 메커니즘**: 부분 실패 시 자동 재시도, state 정합성 검증

> **참고**: 점진적 Connection API(추가/제거)는 Optional 기능입니다. Phase 1의 일괄 생성/삭제만으로도 Tumblebug MCI 기반 Full-Mesh VPN 시나리오를 충분히 지원합니다. 개별 Connection 제거 시에는 Full-Mesh 무결성이 깨질 수 있으므로 주의가 필요합니다 (§2.11 참조).

### 3.4. Phase 3: 모니터링 및 고도화 (장기)

- VPN 터널 상태 모니터링 및 Health Check 통합
- 연결 토폴로지 시각화
- 자동 재연결/복구 메커니즘
- 대역폭 최적화 및 라우팅 메트릭 관리

### 3.5. 당장 실행 가능한 접근 방법

**Step 1: Output 구조 리팩토링 (최우선)**

```hcl
# aws/aws-output.tf (변경 전)
output "aws_vpn_info" {
  value = {
    aws = merge(
      { vpn_gateway = { ... } },
      try(module.conn_aws_azure.aws_vpn_conn_info, {})  # ← 제거!
    )
  }
}

# aws/aws-output.tf (변경 후)
output "aws_vpn_gateway_info" {    # ← 이름 변경: gateway_info
  value = {
    vpn_gateway = {
      resource_type = "aws_vpn_gateway"
      name          = try(aws_vpn_gateway.vpn_gw.tags.Name, "")
      id            = try(aws_vpn_gateway.vpn_gw.id, "")
      vpc_id        = try(aws_vpn_gateway.vpn_gw.vpc_id, "")
    }
  }
}
```

**Step 2: 나머지 Connection 모듈 개발**

기존 `aws-to-site/modules/`를 `site-to-site/modules/conn-{pair}/` 패턴으로 리팩토링:

| aws-to-site 모듈          | site-to-site 모듈 변환             | 차이점                                               |
| ------------------------- | ---------------------------------- | ---------------------------------------------------- |
| `modules/gcp/main.tf`     | `modules/conn-aws-gcp/main.tf`     | AWS 리소스가 variable로 변경 (gateway_id, vpc_id 등) |
| `modules/alibaba/main.tf` | `modules/conn-alibaba-aws/main.tf` | 동일                                                 |
| `modules/tencent/main.tf` | `modules/conn-aws-tencent/main.tf` | 동일                                                 |
| `modules/ibm/main.tf`     | `modules/conn-aws-ibm/main.tf`     | 동일                                                 |

**Step 3: Handler 확장 및 점진적 Connection 관리 API 추가**

`vpn-site-to-site-actions.go`에서 다음 변경을 수행합니다:

1. `len(providers) != 2`를 `len(providers) < 2`로 변경
2. 모든 provider pair에 대해 conn 디렉토리를 복사하는 로직 추가
3. 점진적 Connection 추가/제거 API 엔드포인트 추가
4. Output 함수에서 `{csp}_vpn_gateway_info`와 `conn_{pair}_info`를 분리 수집 → merge
5. `terrarium.DestroyTarget` 함수를 활용한 Connection 제거 handler 추가

### 제약사항 인지 및 Validation

Full-Mesh VPN 구성 시 CSP 특성/제약을 고려하여 API에서 사전 검증합니다:

| 제약사항                       | 상세                           | 영향                                               | Validation 방안                    |
| ------------------------------ | ------------------------------ | -------------------------------------------------- | ---------------------------------- |
| **AWS VGW 10 Connection 제한** | VGW당 최대 10개 VPN Connection | CSP당 2 Connection × 최대 5개 원격 CSP = 10 (한계) | `len(csps)-1 > 5`이면 에러 반환    |
| **Azure APIPA 범위**           | 169.254.21.0 ~ 169.254.22.255  | CSP별 APIPA 할당으로 6개 CSP 동시 연결 가능        | CIDR 충돌 검증                     |
| **BGP ASN 고유성**             | CSP별 고유 ASN 필요            | ASN 충돌 시 BGP 세션 미성립                        | CSP별 고정 ASN으로 보장            |
| **Apply 시간**                 | 모든 CSP의 VPN GW 동시 생성    | 30~60분 소요 예상                                  | Timeout 설정 및 Progress 조회 지원 |
| **Full-Mesh 필수**             | Transit Routing 미지원         | Partial Mesh 시 일부 CSP 간 통신 불가              | 모든 pair 자동 생성으로 보장       |
| **GCP ↔ Static CSP 연결 불가** | GCP HA VPN BGP 필수            | 7-CSP Full-Mesh 시 3쌍 구성 불가 (§2.12)           | GCP 포함 시 Static CSP 제외 필요   |

---

## 4. CSP Pair별 신규 모듈 개발 참조 (conn-aws-gcp 예시)

기존 `aws-to-site/modules/gcp/main.tf`를 기반으로 `site-to-site/modules/conn-aws-gcp/` 모듈을 작성합니다.

### 핵심 차이점: Variable Reference 방식

```hcl
# aws-to-site 방식: 직접 리소스 참조
resource "aws_customer_gateway" "gcp_gw" {
  ip_address = google_compute_ha_vpn_gateway.vpn_gw.vpn_interfaces[count.index].ip_address
  # ↑ 같은 state 내의 GCP 리소스를 직접 참조
}

# site-to-site 모듈 방식: variable 통해 참조
resource "aws_customer_gateway" "gcp_gw" {
  ip_address = var.gcp_vpn_gateway_addresses[count.index]
  # ↑ 상위 레이어에서 variable로 전달받음
}
```

### modules/conn-aws-gcp/variables.tf 예시

```hcl
variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "aws_vpn_gateway_id" {
  description = "AWS VPN Gateway ID"
  type        = string
}

variable "gcp_bgp_asn" {
  description = "GCP BGP ASN"
  type        = string
}

variable "gcp_ha_vpn_gateway_self_link" {
  description = "GCP HA VPN Gateway self link"
  type        = string
}

variable "gcp_router_name" {
  description = "GCP Cloud Router name"
  type        = string
}

variable "gcp_vpn_gateway_addresses" {
  description = "GCP HA VPN Gateway interface IP addresses"
  type        = list(string)
}
```

### conn-aws-gcp/conn-aws-gcp-main.tf 예시

```hcl
module "conn_aws_gcp" {
  source = "./modules/conn-aws-gcp"

  name_prefix    = var.vpn_config.terrarium_id

  # AWS resources (created in aws/ directory)
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id

  # GCP resources (created in gcp/ directory)
  gcp_bgp_asn                  = var.vpn_config.gcp.bgp_asn
  gcp_ha_vpn_gateway_self_link = google_compute_ha_vpn_gateway.vpn_gw.self_link
  gcp_router_name              = google_compute_router.vpn_router.name
  gcp_vpn_gateway_addresses    = google_compute_ha_vpn_gateway.vpn_gw.vpn_interfaces[*].ip_address
}
```

---

## 5. cb-tumblebug 통합 관점 분석

### 5.1. cb-tumblebug의 현재 VPN 통합 구조

```
cb-tumblebug                           mc-terrarium
┌──────────────────────┐              ┌──────────────────────┐
│ POST /vpn            │──POST /tr──▶│ Create terrarium     │
│ (CreateSiteToSiteVPN)│              │                      │
│                      │──POST /tr/  │                      │
│                      │  {trId}/vpn/│ Init+Plan+Apply      │
│                      │  aws-to-site│ (aws-to-site)        │
│                      │──────────▶  │                      │
│                      │              │                      │
│ [Polling loop]       │──GET /tr/   │                      │
│ sigmoid backoff      │  {trId}/vpn/│ Output (refined)     │
│ 120s→10s, 1hr limit  │  aws-to-site│                      │
│                      │──────────▶  │                      │
│                      │              │                      │
│ VpnInfo (KV store)   │              │ terraform.tfstate    │
│ status: Available    │              │ (.terrarium/{trId}/) │
└──────────────────────┘              └──────────────────────┘
```

#### 핵심 특성

| 항목        | 현재 상태                                                                         |
| ----------- | --------------------------------------------------------------------------------- |
| 지원 API    | `/tr/{trId}/vpn/aws-to-site`만 사용 (site-to-site API 미사용)                     |
| Hub 제한    | **AWS만 hub** (`supportedCspForVpn`에 AWS만 key로 존재)                           |
| VPN 단위    | 1:1 (VPN 1개 = Terrarium 1개 = aws-to-site 1 pair)                                |
| 상태 관리   | cb-tumblebug: `Configuring`→`Available`→`Deleting` / mc-terrarium: OpenTofu state |
| ID 매핑     | `VpnInfo.Uid` = `TerrariumInfo.Id` (1:1)                                          |
| 리소스 조회 | mc-terrarium output에서 추출 → KV store에 캐시                                    |
| 데이터 모델 | `VpnInfo.VpnSites[0]` = hub(AWS), `VpnSites[1]` = spoke                           |
| 에러 복구   | `?action=retry` 파라미터 지원 (KV에서 기존 정보 로드 후 재시도)                   |

### 5.2. Option D 통합 시 cb-tumblebug 영향 분석

#### Scenario A: 현재처럼 1:1 VPN (가장 간단)

Option D를 적용하더라도, cb-tumblebug이 여전히 1:1 pair VPN만 관리한다면:

```
변경 필요 사항:
  - mc-terrarium API 경로 변경: /vpn/aws-to-site → /vpn/site-to-site
  - Request body 변경: CreateAwsToSiteVpnRequest → CreateSiteToSiteVpnRequest
  - Output 파싱 변경: {csp}_vpn_info → {csp}_vpn_gateway_info + conn_{pair}_info
  - supportedCspForVpn에 다른 hub CSP 추가 가능

cb-tumblebug 변경량: 중간 (API 호출 변경 + output 파싱)
복잡도: 낮음
```

#### Scenario B: Multi-pair VPN (N개 CSP를 하나의 VPN으로 관리) — Option D의 진정한 이점

```
현재 (1:1):
  vpn-01: AWS ↔ Azure     (terrarium: tr-vpn01)
  vpn-02: AWS ↔ GCP       (terrarium: tr-vpn02)  ← 별도 VPN, 별도 terrarium
  vpn-03: Azure ↔ GCP     (terrarium: tr-vpn03)  ← 불가능 (Azure hub 미지원)

Option D (N:N):
  vpn-01: AWS ↔ Azure ↔ GCP  (terrarium: tr-vpn01, 단일 terrarium에서 전체 관리)
```

이를 위한 cb-tumblebug 변경:

```
1. 데이터 모델 변경
   현재: VpnInfo.VpnSites = [site1(hub), site2(spoke)]  (고정 2개)
   변경: VpnInfo.VpnSites = [site1, site2, ... siteN]    (가변 N개)
         VpnInfo.Connections = [{pair: "aws-azure"}, {pair: "aws-gcp"}, {pair: "azure-gcp"}]

2. API 변경
   현재: POST /vpn (site1 + site2)
   변경: POST /vpn (sites: [site1, site2, ..., siteN])
         POST /vpn/{vpnId}/connections (add new site)
         DELETE /vpn/{vpnId}/connections/{pair} (remove connection)

3. mc-terrarium 호출 변경
   현재: POST /tr/{trId}/vpn/aws-to-site
   변경: POST /tr/{trId}/vpn/site-to-site (N CSPs)
         POST /tr/{trId}/vpn/site-to-site/connections (새 CSP 추가)
         DELETE /tr/{trId}/vpn/site-to-site/connections/{pair} (Targeted Destroy로 제거)

4. Polling 변경
   현재: GET /tr/{trId}/vpn/aws-to-site?detail=refined
   변경: GET /tr/{trId}/vpn/site-to-site?detail=refined
```

### 5.3. cb-tumblebug 통합 용이성 평가

| 평가 항목               | Option C (GW/Conn 분리)                    | Option D (점진적 구성)                |
| ----------------------- | ------------------------------------------ | ------------------------------------- |
| cb-tumblebug API 변경량 | 높음 (gateway + connection 2단계 API 필요) | **낮~중** (기존 패턴 확장)            |
| Terrarium ID 관리       | 복잡 (GW terrarium + Conn terrarium 다수)  | **단순** (VPN당 1개 terrarium)        |
| 상태 모델 복잡도        | 높음 (GW 상태 + Conn 상태 별도 추적)       | **중간** (VPN 상태 + Connection 목록) |
| 점진적 구성 지원        | 가능하나 복잡                              | **자연스러움**                        |
| 기존 패턴 호환성        | 낮음 (새 워크플로우 필요)                  | **높음** (기존 패턴 확장)             |
| Polling 패턴            | 2단계 각각 polling 필요                    | **1단계 polling** (기존과 동일)       |
| 에러 복구               | 복잡 (GW/Conn 각각 복구)                   | **단순** (단일 terrarium 복구)        |

### 5.4. cb-tumblebug 모델 변경 제안

```go
// 현재 모델 (1:1 pair)
type RestPostVpnRequest struct {
    Name  string       `json:"name"`
    Site1 SiteProperty `json:"site1"`     // 고정 2개
    Site2 SiteProperty `json:"site2"`
}

// 제안 모델 (N CSP 지원, 하위 호환 유지)
type RestPostVpnRequest struct {
    Name  string         `json:"name"`
    // 기존 필드 유지 (하위 호환)
    Site1 *SiteProperty  `json:"site1,omitempty"`
    Site2 *SiteProperty  `json:"site2,omitempty"`
    // 신규 필드 (N CSP 지원)
    Sites []SiteProperty `json:"sites,omitempty"`
}

// VPN 정보 모델 확장
type VpnInfo struct {
    ResourceType string          `json:"resourceType"`
    Id           string          `json:"id"`
    Uid          string          `json:"uid"`
    Name         string          `json:"name"`
    Description  string          `json:"description"`
    Status       string          `json:"status"`
    VpnSites     []VpnSiteDetail `json:"vpnSites"`
    // 신규: 활성 연결 목록
    Connections  []VpnConnection `json:"connections,omitempty"`
}

type VpnConnection struct {
    Pair   string `json:"pair" example:"aws-azure"`    // Connection pair 이름
    Status string `json:"status" example:"Available"`  // 개별 connection 상태
}
```

### 5.5. 통합 결론

1. **Option D는 cb-tumblebug 통합에 적합합니다**: 1 VPN = 1 Terrarium 매핑을 유지하면서 N-CSP 확장 가능
2. **기존 통합 패턴을 보존**: POST(생성) → Polling(완료 대기) → GET(결과) 패턴 그대로 사용 가능
3. **점진적 마이그레이션 가능**:
   - Phase 1: 기존 aws-to-site API 유지 + site-to-site API 병행 (cb-tumblebug 변경 최소화)
   - Phase 2: cb-tumblebug을 site-to-site API로 전환
   - Phase 3: connection 추가/제거 API 통합
4. **Option C 대비 통합 복잡도 대폭 감소**: Gateway/Connection 분리 시 cb-tumblebug이 여러 terrarium을 관리해야 하지만, Option D는 단일 terrarium으로 충분

---

## 6. 결론 및 논의 사항

### 6.1. 현재 상태

- aws-to-site: 6개 CSP 연결 완성 (Star 토폴로지)
- site-to-site: 3개 pair 모듈 완성 (aws-azure, azure-gcp, alibaba-azure)
- Option C(Gateway/Connection 분리)는 구현 복잡도, 사용자 복잡도, 연결 제거 어려움으로 인해 보류

### 6.2. Option D (Single-Terrarium Incremental Composition) — 설계 완료, 구현 보류

Option D는 현재 site-to-site 구조를 기반으로, 다음 핵심 문제를 해결하는 설계입니다:

1. **구현 복잡도**: 기존 코드 확장으로 구현. 새 아키텍처 패턴 불필요
2. **사용자 복잡도**: 단일 Terrarium, N-CSP 일괄 생성/삭제 API로 간단한 인터페이스
3. **안전한 전체 삭제**: Phased Destroy(Connection → Gateway 순서) → 부분 실패 시 재시도 가능
4. **Transit Routing 해결**: Full-Mesh 토폴로지로 모든 CSP pair 직접 연결 → Transit 불필요 (§2.11)

그러나 다음 제약사항들로 인해 **현 시점에서 구현을 추진하기에는 시기상조**로 판단됩니다:

#### 구현 보류 사유

1. **GCP ↔ Static CSP 직접 연결 불가** (§2.12): GCP HA VPN의 BGP 필수 요구로 인해 Tencent·IBM·DCS와의 직접 연결 불가. 7-CSP 완전 Full-Mesh를 달성할 수 없음
2. **Transit Routing 미지원** (§2.11): Partial Mesh로 대체할 수 없으므로, 연결 불가 쌍은 통신 자체가 불가능
3. **개발 공수 대비 효과**: 12개 신규 Connection 모듈 개발 + Handler 확장이 필요하나, 위 제약으로 "완전한" Full-Mesh를 제공할 수 없어 투자 대비 효과가 제한적
4. **기존 aws-to-site의 실용성**: Star 토폴로지(AWS Hub)는 이미 6개 CSP 연결을 완성했으며, 소규모 Multi-Cloud VPN 시나리오에서 충분히 실용적

#### 향후 재검토 조건

- GCP Classic VPN 대체 수단 등장 또는 GCP HA VPN의 Static Routing 지원
- AWS Transit Gateway 기반 아키텍처로 전환 시 (VGW 10 Connection 제한 해소)
- Tencent CCN 또는 IBM Transit Gateway 등 BGP 지원 확대
- 사용자 수요에 의한 우선순위 변경

### 6.3. 설계된 실행 순서 (참조용)

| 순서 | 작업                                                             | 기간      | 난이도 | 우선도   |
| ---- | ---------------------------------------------------------------- | --------- | ------ | -------- |
| 0-1  | Output 구조 리팩토링 (교차 참조 제거, 이름 고유화, 표준화)       | 1주       | 낮음   | 필수     |
| 0-2  | 나머지 12개 conn 모듈 개발                                       | 1~2개월   | 중     | 필수     |
| 1    | **N-CSP 일괄 생성/삭제 API + Phased Destroy + CSP Validation** ★ | 0.5~1개월 | 중     | **핵심** |
| 2    | 안정화 + 점진적 Connection API (Optional)                        | 1~2개월   | 중     | 선택     |

### 6.4. 핵심 기술적 결정 사항 (설계 기록)

1. **Full-Mesh 일괄 생성/삭제가 Primary API**이다 → 점진적 Connection 관리는 Optional
2. **Full-Mesh를 보장한다** → Transit Routing 미지원이므로 모든 pair를 자동 생성
3. **Gateway output은 connection을 참조하지 않는다** → 교차 참조 문제 해결
4. **모든 CSP의 gateway output 이름을 `{csp}_vpn_gateway_info`로 표준화한다** → 비표준 output 통일
5. **Connection output은 pair 고유 이름을 사용한다** → `conn_{pair}_info` 형식
6. **전체 Destroy는 Phased Destroy를 사용한다** → Connection → Gateway 순서 (§2.4)
7. **Handler가 파일 존재 여부로 활성 connection을 판단한다** → 워크스페이스가 진실의 원천(source of truth)
8. **CSP 제약사항을 API에서 사전 검증한다** → AWS VGW 10 Connection 제한 등 (§2.6)
9. **Dynamic/Static Routing 하이브리드는 Connection 레벨에서 가능하다** → 단, GCP는 BGP-only (§2.12)

### 6.5. 미결 논의 사항

1. 나머지 CSP pair 모듈 개발 우선순위 확정
2. AWS Transit Gateway 도입 시점 (VGW 10 Connection 제한으로 6+ CSP 동시 연결 불가)
3. DCS를 Full-Mesh 범위에 포함할 것인지 (OpenStack VPNaaS 특성상 제약)
4. Connection 모듈 개발 시 각 CSP pair의 테스트 환경 확보
5. 점진적 Connection 제거 시 Full-Mesh 무결성 경고/차단 정책
6. GCP ↔ Static CSP 연결 불가 문제의 대안 탐색 (Classic VPN, Transit Gateway 등)
7. BGP 4-CSP 한정 Full-Mesh(AWS, Azure, GCP, Alibaba) MVP의 가치 판단

---

## References

### CSP VPN 공식 문서

- **AWS**
  - [AWS Site-to-Site VPN 사용 설명서](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
  - [AWS VPN Gateway 할당량](https://docs.aws.amazon.com/vpn/latest/s2svpn/vpn-limits.html)
  - [AWS BGP 정보 및 터널 옵션](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPNTunnels.html)
- **Azure**
  - [Azure VPN Gateway 설명서](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)
  - [Azure VPN Gateway FAQ (APIPA/BGP 포함)](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-vpn-faq)
  - [Azure Active-Active VPN Gateway 구성](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-activeactive-rm-powershell)
- **GCP**
  - [GCP HA VPN 개요](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview)
  - [GCP Cloud Router BGP 구성](https://cloud.google.com/network-connectivity/docs/router/concepts/overview)
  - [GCP HA VPN과 AWS 연결 가이드](https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-aws)
- **Alibaba Cloud**
  - [Alibaba Cloud VPN Gateway 개요](https://www.alibabacloud.com/help/en/vpn-gateway/product-overview/what-is-vpn-gateway)
  - [Alibaba Cloud IPsec-VPN 연결](https://www.alibabacloud.com/help/en/vpn-gateway/user-guide/create-an-ipsec-vpn-connection)
- **Tencent Cloud**
  - [Tencent Cloud VPN 연결 개요](https://www.tencentcloud.com/document/product/1037/32679)
  - [Tencent Cloud IPsec VPN 연결 생성](https://www.tencentcloud.com/document/product/1037/32689)
  - [Tencent Cloud VPN 경로 구성](https://www.tencentcloud.com/document/product/1037/39690)
- **IBM Cloud**
  - [IBM Cloud VPN for VPC 개요](https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-overview)
  - [IBM Cloud VPN Gateway 생성](https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-create-gateway)
  - [IBM Cloud VPN Connection 추가](https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-adding-connections)
- **OpenStack (DCS)**
  - [OpenStack VPNaaS 시나리오](https://docs.openstack.org/neutron/latest/admin/vpnaas-scenario.html)
  - [OpenStack Networking API v2 — VPNaaS](https://docs.openstack.org/api-ref/network/v2/)

### CSP 간 VPN 연결 참조

- [GCP-AWS 간 HA VPN 구성 튜토리얼](https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-aws)
- [GCP-Azure 간 HA VPN 구성 튜토리얼](https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-azure)

### OpenTofu / IaC 관련

- [OpenTofu 공식 문서](https://opentofu.org/docs/)
- [OpenTofu CLI — `tofu destroy -target`](https://opentofu.org/docs/cli/commands/destroy/)
- [OpenTofu State 관리](https://opentofu.org/docs/language/state/)

### MC-Terrarium 관련

- [MC-Terrarium GitHub 리포지토리](https://github.com/cloud-barista/mc-terrarium)
- [cb-tumblebug GitHub 리포지토리](https://github.com/cloud-barista/cb-tumblebug)

---

## Appendix A: 현재 상태 분석

### A.1. 기존 구현 현황

현재 MC-Terrarium에는 두 가지 VPN 구현 방식이 존재합니다:

| 구현             | 경로                          | 상태      | 설명                                                                               |
| ---------------- | ----------------------------- | --------- | ---------------------------------------------------------------------------------- |
| **aws-to-site**  | `templates/vpn/aws-to-site/`  | 완성      | AWS를 중심으로 GCP, Azure, Alibaba, Tencent, IBM, DCS에 연결                       |
| **site-to-site** | `templates/vpn/site-to-site/` | 부분 완성 | CSP 간 대칭적 VPN (현재 conn-aws-azure, conn-azure-gcp, conn-alibaba-azure만 구현) |

#### aws-to-site 방식 (Star 토폴로지)

```
         ┌──────────┐
    ┌────┤   AWS    ├────┐
    │    │ VPN GW   │    │
    │    └────┬─────┘    │
    │         │          │
    ▼         ▼          ▼
  GCP      Azure     Alibaba    Tencent    IBM    DCS
```

- AWS VPN Gateway를 허브로 사용
- `target_csp.type`으로 대상 CSP를 선택 (1:1)
- 각 대상 CSP용 모듈이 `modules/{csp}/`에 독립적으로 존재
- 한 terrarium에서 AWS-to-{하나의 CSP} 연결만 가능

#### site-to-site 방식 (대칭 Pair 토폴로지)

```
  AWS ──── Azure ──── GCP
             │
          Alibaba
```

- CSP 양측 각각 gateway를 생성하고, 연결 모듈로 쌍 구성
- 3-tier 구조: `{csp}/` (gateway) → `modules/conn-{csp1}-{csp2}/` (연결 로직) → `conn-{csp1}-{csp2}/` (모듈 호출)
- 현재는 2개 CSP만 선택 가능 (`len(providers) != 2` 검증)
- 연결 가능 조합: aws-azure, azure-gcp, alibaba-azure (3개 조합만 구현)

### A.2. CSP별 VPN Gateway 특성 및 제약사항

| CSP         | VPN Gateway 유형   | BGP 지원         | 터널 수                         | Public IP 수            | 주요 제약                                                                                    |
| ----------- | ------------------ | ---------------- | ------------------------------- | ----------------------- | -------------------------------------------------------------------------------------------- |
| **AWS**     | VPN Gateway (VGW)  | ✅               | Connection당 2개 자동생성       | VGW당 할당              | VPC당 VGW 1개, VGW당 최대 10 VPN Connection                                                  |
| **Azure**   | Virtual Network GW | ✅               | Connection당 1개                | Active-Active 시 2개    | VNet당 VPN GW 1개, VpnGw1AZ: 최대 30 터널, APIPA 주소 범위 제한(169.254.21.0~169.254.22.255) |
| **GCP**     | HA VPN Gateway     | ✅               | GW당 interface 2개 × 터널       | HA GW 시 2개            | External GW에 redundancy type 필요, Router interface/peer 개수 제한                          |
| **Alibaba** | VPN Gateway        | ✅               | Connection당 2개 (master/slave) | 1개 (+ DR IP)           | VPC당 VPN GW 수 제한, dual VSwitch 필요                                                      |
| **Tencent** | VPN Gateway        | ❌ (Static)      | Connection당 1개                | GW당 1개                | BGP 미지원(IPSEC type), StaticRoute만 가능, APIPA 범위 별도(169.254.128.0/17)                |
| **IBM**     | VPN Gateway        | ❌ (Route-based) | Connection당 1개                | GW당 2개                | BGP 미지원, Policy-based/Route-based 선택, Routing table 순차적 생성 필요                    |
| **DCS**     | VPNaaS (OpenStack) | ❌ (Static)      | Site Connection당 1개           | VPN Service 외부 IP 1개 | VPNaaS 기반, BGP 미지원, Endpoint Group 기반                                                 |

#### 핵심 제약사항 요약

1. **AWS VGW: VPC당 1개만 가능** → 하나의 VPN Gateway로 여러 CSP 연결 필수
2. **Azure VPN GW: VNet당 1개만 가능** → 하나의 Gateway에 여러 연결을 추가해야 함
3. **Azure APIPA 범위 제한** → 169.254.21.0~169.254.22.255 범위 내에서만 BGP peering 가능 (최대 약 128개 /30 서브넷)
4. **GCP HA VPN GW: Interface 2개 고정** → 하나의 GW당 최대 연결 수가 제한됨
5. **Tencent/IBM/DCS: BGP 미지원** → Static routing 필요, Route 수동 관리 필요
6. **Alibaba: dual VSwitch 필요** → 가용 영역 2개가 필요

---

## Appendix B: 다른 방안 검토 (Options A, B, C)

### B.1. Full-Mesh VPN의 도전과제 상세

#### B.1.1. VPN Gateway 단일성 제약

**문제**: AWS VPC당 VGW 1개, Azure VNet당 VPN GW 1개 제약

예시: AWS-Azure VPN과 AWS-GCP VPN을 별도 terrarium에서 생성하면

- 첫 번째 terrarium: AWS VGW-1 생성, Azure VPN GW-1 생성
- 두 번째 terrarium: **충돌** — 같은 VPC에 AWS VGW-2 생성 불가

**→ 하나의 Terrarium 내에서 하나의 VPN Gateway에 여러 Connection을 추가하는 구조가 필수**

#### B.1.2. OpenTofu State 관리 복잡성

현재 각 terrarium은 독립적인 OpenTofu state를 가짐:

- `.terrarium/{trId}/vpn/site-to-site/terraform.tfstate`

하나의 terrarium에 모든 CSP의 VPN gateway와 connection이 포함되면:

- State가 매우 커짐
- 하나의 연결 변경(추가/삭제)이 전체 인프라에 영향 가능
- Apply 시간이 크게 증가

#### B.1.3. APIPA 주소 관리

Azure의 APIPA 범위가 제한적(169.254.21.0~169.254.22.255):

- /30 서브넷 단위 = 4바이트씩 나눔
- 범위 내 총 $\frac{512}{4} = 128$ 개 /30 서브넷
- AWS 연결에 4개, GCP에 4개, Alibaba에 4개 등 CSP별 할당 관리 필요
- 현재 variables.tf에 CSP별 APIPA 범위가 이미 정의되어 있음 (충돌 방지)

#### B.1.4. CSP별 터널/Connection Quota

Full-Mesh에서 하나의 CSP Gateway가 생성해야 하는 Connection 수:

| CSP     | 다른 6개 CSP 연결 시 Connection 수 | 터널 수 (대략) | Quota 여유                                    |
| ------- | ---------------------------------- | -------------- | --------------------------------------------- |
| AWS     | 6 × 2 = 12 connection              | 24 tunnels     | VGW당 최대 10 connection → **초과**           |
| Azure   | 6 × 2~4 = 12~24 connection         | 12~24 tunnels  | VpnGw1AZ 최대 30 → 가능, APIPA 주소 관리 필요 |
| GCP     | 6 × 2~4 = 12~24 tunnels            | 12~24 tunnels  | Quota 내 가능                                 |
| Alibaba | 6 × 2 connection                   | 12 tunnels     | 확인 필요                                     |
| Tencent | 6 × 2 GW × 2 conn = 24             | 24 connections | GW 수 제한 확인 필요                          |
| IBM     | 6 × 4 connection                   | 24 connections | 확인 필요                                     |

**→ AWS VGW의 Connection 제한(10개)으로 인해 동시에 6개 CSP 모두 연결 시 초과 발생 가능**

### B.2. Option A: 단일 Terrarium Full Mesh (비권장)

```
하나의 terrarium에 모든 CSP gateway + 모든 connection
└── .terrarium/{trId}/vpn/site-to-site/
    ├── aws/          (VPN GW)
    ├── azure/        (VPN GW)
    ├── gcp/          (VPN GW)
    ├── alibaba/      (VPN GW)
    ├── tencent/      (VPN GW)
    ├── ibm/          (VPN GW)
    ├── conn-aws-azure/
    ├── conn-aws-gcp/
    ├── conn-alibaba-aws/
    ├── ... (21개 조합 모두)
```

**장점**: 하나의 state에서 모든 리소스 관리, VPN Gateway 공유가 자연스러움

**단점**: State가 거대해짐, 하나의 연결 변경이 전체에 영향, Apply/Destroy 시간 매우 김, AWS VGW 10 Connection 제한으로 Full mesh 불가, 부분 실패 시 롤백 매우 어려움

### B.3. Option B: Hub-Spoke 기반 확장

```
AWS를 Hub로, 각 CSP를 Spoke로 연결 (현재 aws-to-site 확장)
추가 연결이 필요한 CSP pair는 별도 terrarium으로 구성

Terrarium-1: AWS-to-Azure    (aws-to-site)
Terrarium-2: AWS-to-GCP      (aws-to-site)
Terrarium-3: AWS-to-Alibaba  (aws-to-site)
Terrarium-4: Azure-to-GCP    (site-to-site, 별도 Azure/GCP GW 사용 시)
```

**장점**: 기존 aws-to-site 구현 활용 가능, 각 연결이 독립적으로 관리됨, 부분 실패 복구 용이

**단점**: AWS VGW, Azure VPN GW가 terrarium마다 중복 생성 시도 → VPC당 1개 제약 위반, VPN Gateway를 외부에서 생성하고 import하는 패턴 필요, Transit 라우팅이 자동으로 되지 않음

### B.4. Option C: Gateway/Connection 분리 (개발 과정에서 문제 발견)

```
Phase 1: Gateway 프로비저닝 (per CSP, per VPC)
  Terrarium: "gw-aws-vpc1"    → AWS VPN Gateway only
  Terrarium: "gw-azure-vnet1" → Azure VPN Gateway only

Phase 2: Connection 프로비저닝 (per CSP pair)
  Terrarium: "conn-aws-azure" → AWS-Azure VPN Connections only
  Terrarium: "conn-aws-gcp"   → AWS-GCP VPN Connections only
```

**장점**: Gateway 재사용, 독립적 생명주기, Quota 관리 용이, 점진적 확장

**단점**: 아키텍처 변경 필요, Terrarium 간 state 참조 메커니즘 필요, 사용자 워크플로우 2단계 분리

#### Option C에서 발견된 문제점

실제 개발 과정에서 다음 세 가지 핵심 문제가 발견되었습니다:

**문제 1**: 구현 복잡도 과다 — Terrarium 간 State 참조 메커니즘 (`terraform_remote_state` 또는 data source), Gateway/Connection 각각의 생명주기 관리 로직

**문제 2**: 상위 서브시스템/사용자의 복잡한 구성 — 2단계 워크플로우 강제, 사용자가 Gateway ID/Public IP 등을 수동 전달, cb-tumblebug에서 2단계 오케스트레이션 부담

**문제 3**: 연결 제거 어려움 — Output 교차 참조 문제 (gateway output에서 connection module 참조), Output 이름 충돌 (같은 CSP의 conn info가 여러 pair에서 중복 정의)

> 이러한 문제점을 해결하기 위해 **Option D(Single-Terrarium Incremental Composition)** 가 제안되었습니다. 본 문서의 [Section 2](#2-option-d-single-terrarium-incremental-composition)를 참조하십시오.
