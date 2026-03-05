# Planning for Small-Scale Full-Mesh VPN

> **Date**: February 2025 – March 2026  
> **Status**: Archive — Implementation Deferred  
> **Conclusion**: Small-scale (2–7 CSPs) Full-Mesh VPN configuration is technically designable, but is deemed premature for implementation at this time due to the constraints listed below. Will be revisited when CSP support expands or architectural changes occur.
> **Co-authored**: Collaboratively written with GitHub Copilot (Claude Opus 4.6) through approximately 30 rounds of Q&A and author review
>
> **Korean version**: [planning-for-full-mesh-vpn.ko.md](planning-for-full-mesh-vpn.ko.md)

### Key Constraints Identified

| #   | Constraint                                          | Severity | Description                                                                                                                                                                                                             |
| --- | --------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **GCP ↔ Static CSP direct connection not possible** | Critical | GCP HA VPN requires BGP, but Tencent, IBM, and DCS do not support BGP. In a 7-CSP Full-Mesh, 3 pairs (GCP↔Tencent, GCP↔IBM, GCP↔DCS) cannot be configured, making complete Full-Mesh unachievable                       |
| 2   | **Transit Routing not supported**                   | Critical | All CSP VPN Gateways do not re-advertise BGP-learned routes. Communication via intermediate hops is impossible in Partial Mesh → Full-Mesh is mandatory. However, constraint #1 makes 7-CSP Full-Mesh itself impossible |
| 3   | **AWS VGW 10 Connection limit**                     | High     | Maximum 10 VPN Connections per AWS VPN Gateway. At 2 Connections per CSP, only 5 remote CSPs can connect → quota exceeded with 6+ simultaneous CSPs                                                                     |
| 4   | **12 Connection modules not implemented**           | High     | Of Full-Mesh $\binom{7}{2} = 21$ pairs, only 3 are implemented (conn-aws-azure, conn-azure-gcp, conn-alibaba-azure). Developing the remaining 12 (+ 6 impossible) modules requires significant effort                   |
| 5   | **Azure APIPA address range limitation**            | Medium   | APIPA range for BGP Peering is limited to 169.254.21.0–169.254.22.255. Address allocation management becomes complex with multiple simultaneous CSP connections                                                         |
| 6   | **Apply time**                                      | Medium   | Simultaneous creation of N CSP VPN Gateways is expected to take 30–60 minutes                                                                                                                                           |

> **Note**: The combination of constraints #1 and #2 is the most critical. In a Full-Mesh including GCP, direct connection with Static CSPs (Tencent, IBM, DCS) is impossible, and Transit Routing cannot substitute. Therefore, 7-CSP complete Full-Mesh is unachievable with current CSP technology. Reducing scope to 4 BGP-capable CSPs (AWS, Azure, GCP, Alibaba) enables Full-Mesh, but excludes Tencent, IBM, and DCS users.

---

## 1. Overview

### 1.1. Objective

Full-Mesh VPN configuration connecting N CSPs' VPCs/VNets to each other:

```
      AWS ──── Azure
     / | \    / | \
   GCP |  \ /  | Tencent
    \  |   X   |  /
     \ |  / \  | /
   Alibaba── IBM
```

- 7 CSPs: AWS, Azure, GCP, Alibaba, Tencent, IBM, DCS
- Full-Mesh combinations: $\binom{7}{2} = 21$ pairs (however, 3 GCP ↔ Static CSP pairs are technically infeasible)
- Users can select desired CSP combinations for VPN configuration

### 1.2. Key Challenges

| Challenge                                    | Description                                                                                      |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **VPN Gateway singularity constraint**       | 1 VGW per AWS VPC, 1 VPN GW per Azure VNet → multiple connections must share a single GW         |
| **OpenTofu State management**                | State size and apply time increase with N-CSP management                                         |
| **APIPA address conflicts**                  | CSP-specific allocation management needed within Azure APIPA range (169.254.21.0–169.254.22.255) |
| **CSP tunnel/Connection Quota**              | AWS VGW max 10 Connections, per-GW tunnel limits, etc.                                           |
| **CSPs without BGP support**                 | Tencent, IBM, DCS support only static routing                                                    |
| **GCP ↔ Static CSP connection not possible** | GCP HA VPN requires BGP → direct VPN connection with Tencent, IBM, DCS not possible (§2.12)      |
| **Transit Routing not supported**            | CSP VPN GWs do not re-advertise learned routes → Full-Mesh required (§2.11)                      |

### 1.3. Current State Summary

| Implementation   | Status             | Description                                                                                           |
| ---------------- | ------------------ | ----------------------------------------------------------------------------------------------------- |
| **aws-to-site**  | Complete           | Connects AWS as hub to GCP, Azure, Alibaba, Tencent, IBM, DCS (Star topology)                         |
| **site-to-site** | Partially complete | Symmetric Pair VPN between CSPs (only conn-aws-azure, conn-azure-gcp, conn-alibaba-azure implemented) |

> For detailed analysis of the current state, see [Appendix A](#appendix-a-current-state-analysis).

### 1.4. Options Review Summary

After reviewing multiple options, **Option D (Single-Terrarium Incremental Composition)** is recommended:

| Criteria                  | Option A (Full Mesh)     | Option B (Hub-Spoke)          | Option C (GW Separation)     | **Option D (Incremental)**  |
| ------------------------- | ------------------------ | ----------------------------- | ---------------------------- | --------------------------- |
| Implementation complexity | Medium                   | Low                           | **High**                     | **Medium-Low**              |
| User complexity           | Low                      | Low                           | **High**                     | **Low**                     |
| Connection removal        | Difficult (full rebuild) | Easy (independent terrarium)  | Medium (cross-state release) | **Easy (Targeted Destroy)** |
| Gateway sharing           | Natural                  | Not possible (GW duplication) | Full support                 | **Natural**                 |
| Incremental expansion     | Not possible             | Possible                      | Possible                     | **Possible**                |
| State management          | Large (inefficient)      | Distributed (efficient)       | Distributed (efficient)      | Medium (practical)          |
| Existing code reuse       | High                     | Medium                        | Low (new structure)          | **High**                    |
| Short-term applicability  | Low                      | Medium                        | Low                          | **High**                    |

> For detailed analysis of other options, see [Appendix B](#appendix-b-other-options-review-options-a-b-c).

---

## 2. Option D: Single-Terrarium Incremental Composition

### 2.1. Core Idea

**A structure that provides bulk creation/deletion of all VPN Gateways and Connections for N-CSPs within a single Terrarium as the primary feature, with incremental Connection addition/removal as an optional extension.**

- **Primary**: Specify N CSPs → bulk create/delete all Gateways + all $\binom{N}{2}$ Connections
- **Optional**: Add `.tf` files → `tofu apply` → create only those resources (incremental addition)
- **Optional**: `tofu destroy -target=module.conn_{pair}` → success → delete `.tf` files → destroy only those resources
- Full-Mesh guarantee → Transit Routing unnecessary (§2.11)

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
                     │  terraform.tfstate ← single state       │
                     └─────────────────────────────────────────┘
```

### 2.2. Technical Challenge Resolution

#### Challenge 1: Remove Connection References from Gateway Output

**Problem**: Currently `aws-output.tf` directly references connection modules:

```hcl
# templates/vpn/site-to-site/aws/aws-output.tf (current)
output "aws_vpn_info" {
  value = {
    aws = merge(
      { vpn_gateway = { ... } },
      try(module.conn_aws_azure.aws_vpn_conn_info, {})  # ← cross-reference!
    )
  }
}
```

In this structure, removing the `conn-aws-azure` module invocation causes `module.conn_aws_azure` to disappear from the configuration, resulting in an OpenTofu parsing error. (`try()` only handles runtime errors; it cannot handle configuration-level module reference absence.)

**Solution**: Separate gateway outputs to contain only gateway information:

```hcl
# aws/aws-output.tf (after change)
output "aws_vpn_gateway_info" {    # ← name changed to gateway_info
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
# ↑ No connection module references → unaffected by connection add/remove
```

> **Note**: Currently `azure-output.tf` has connection references commented out, and `gcp-output.tf` is already separated as `gcp_vpn_gateway_info`. Only the AWS output requires actual modification.

#### Challenge 2: Connection Output Name Collision Resolution

**Problem**: Current connection output file output names duplicate per CSP:

```hcl
# conn-aws-azure/conn-aws-azure-output.tf
output "azure_vpn_conn_info" { ... }

# conn-azure-gcp/conn-azure-gcp-output.tf
output "azure_vpn_conn_info" { ... }  # ← name collision!
```

When configuring AWS+Azure+GCP simultaneously, `azure_vpn_conn_info` is defined twice, causing an OpenTofu error.

**Solution**: Use pair-unique output names:

```hcl
# conn-aws-azure/conn-aws-azure-output.tf (after change)
output "conn_aws_azure_info" {       # ← pair-unique name
  description = "AWS-Azure VPN connection details"
  value = {
    aws   = try(module.conn_aws_azure.aws_vpn_conn_info, {})
    azure = try(module.conn_aws_azure.azure_vpn_conn_info, {})
  }
}

# conn-azure-gcp/conn-azure-gcp-output.tf (after change)
output "conn_azure_gcp_info" {       # ← pair-unique name, no collision
  description = "Azure-GCP VPN connection details"
  value = {
    azure = try(module.conn_azure_gcp.azure_vpn_conn_info, {})
    gcp   = try(module.conn_azure_gcp.gcp_vpn_conn_info, {})
  }
}
```

#### Challenge 3: Provider Configuration Lifecycle Management

When fully removing a CSP, the provider configuration file ordering needs management.

**Safe removal sequence using Targeted Destroy**:

```
Connection resource destruction:
  1. tofu destroy -target=module.conn_aws_azure -auto-approve
  2. On success: delete conn-aws-azure-main.tf, conn-aws-azure-output.tf
  3. tofu init (clean up module references)

Full CSP removal (optional):
  4. tofu destroy -target=aws_vpn_gateway.vpn_gw -auto-approve
     (aws_vpn_gateway_route_propagation.main is auto-deleted due to VPN GW dependency)
  5. On success: delete aws-vpn-gw.tf, aws-output.tf
  6. Delete aws-provider.tf (safe since no resources remain)
  7. tofu init
```

**Key**: Provider files must only be removed after all resources for that CSP have been destroyed.

#### Challenge 4: Gateway Output Pattern Standardization

**Problem**: Current gateway output patterns are inconsistent across CSPs:

| CSP     | Current Output Name                                              | Output Structure                              |
| ------- | ---------------------------------------------------------------- | --------------------------------------------- |
| AWS     | `aws_vpn_info` (includes conn references)                        | Merged object (gateway + conn mixed)          |
| Azure   | `azure_vpn_info`                                                 | Merged object (conn references commented out) |
| GCP     | `gcp_vpn_gateway_info`, `gcp_router_info`                        | Separated outputs (already correct)           |
| Alibaba | `alibaba_vpn_gateway_id`, `alibaba_vpn_gateway_internet_ip`, ... | **Individual outputs** (non-standard)         |

**Solution**: Standardize all CSP gateway outputs to `{csp}_vpn_gateway_info` format:

```hcl
# alibaba/alibaba-output.tf (after change ← consolidate current individual outputs)
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

The output collection pattern in the handler is also unified accordingly:

```go
// gateway info: "{csp}_vpn_gateway_info" (common for all CSPs)
for _, provider := range providers {
    targetObject := fmt.Sprintf("%s_vpn_gateway_info", provider)
    gatewayInfo, _ := terrarium.Output(trId, reqId, targetObject, "-json")
    mergeResourceInfo(result, gatewayInfo)
}

// connection info: "conn_{pair}_info" (pair-unique)
for i := 0; i < len(providers); i++ {
    for j := i + 1; j < len(providers); j++ {
        pair := fmt.Sprintf("%s_%s", providers[i], providers[j])
        targetObject := fmt.Sprintf("conn_%s_info", pair)
        connInfo, err := terrarium.Output(trId, reqId, targetObject, "-json")
        if err != nil {
            continue  // skip if no connection for this pair
        }
        mergeResourceInfo(result, connInfo)
    }
}
```

### 2.3. Connection Removal Strategy: Targeted Destroy

If `.tf` files are deleted before destroying the connection, an "orphaned resource" problem occurs on apply failure:

```
Dangerous flow (delete file → apply):
  delete conn-aws-gcp-main.tf → tofu apply → GCP tunnel destroy fails ❌
  → .tf file: gone (already deleted)
  → State: GCP tunnel still exists
  → Result: "orphaned" resource with no management code
```

**Solution: Targeted Destroy** — Instead of deleting `.tf` files first, use `tofu destroy -target` to destroy resources of a specific module first, then delete `.tf` files only upon success.

```bash
# Destroy only a specific connection module
tofu destroy -target=module.conn_aws_gcp -auto-approve
```

#### Workflow

```
Safe flow (destroy → delete files):
  1. tofu destroy -target=module.conn_aws_gcp -auto-approve
     → Success ✅: delete conn-aws-gcp-main.tf, conn-aws-gcp-output.tf → tofu init
     → Failure ❌: files remain untouched, no action needed. Retry possible.
```

#### Advantages

| Item                      | Delete files then apply                         | Targeted Destroy (-target)              |
| ------------------------- | ----------------------------------------------- | --------------------------------------- |
| File state                | Deleted (unrecoverable)                         | **Files untouched**                     |
| Recovery on failure       | Orphaned resource → manual recovery             | **No recovery needed** (just retry)     |
| Dependency graph          | Potentially incomplete with module removed      | **Destroy with complete graph**         |
| Implementation complexity | Separate recovery logic needed                  | **Simple** (destroy → success → delete) |
| State consistency         | State-config mismatch possible on apply failure | **Always consistent**                   |

#### Handler Pseudocode

```go
func removeConnection(trId, pair, reqId string) error {
    workingDir := getWorkingDir(trId)

    // Step 1: Targeted destroy (destroy resources only, files untouched)
    targetModule := fmt.Sprintf("module.conn_%s", strings.ReplaceAll(pair, "-", "_"))
    _, err := terrarium.DestroyTarget(trId, reqId, targetModule)
    if err != nil {
        // .tf files remain untouched, no recovery needed
        // Just retry
        return fmt.Errorf("failed to destroy connection %s, retry possible: %w", pair, err)
    }

    // Step 2: Destroy succeeded → delete .tf files
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-main.tf"))
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-output.tf"))

    // Step 3: Re-init (clean up module references)
    terrarium.Init(trId, reqId)

    return nil
}
```

#### Function to Add to the terrarium Package

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

    // Add -target options
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

> **Note**: There is currently no dedicated `-target` method in `tfclient`, but the existing `SetArg()` method (client.go line 431) can pass `-target=module.conn_aws_gcp`. Adding a convenience method `Target(resource string)` in the future would be clearer.

#### Various Connection Removal Scenarios

**Scenario 1: Remove a Single Connection**

```bash
# Remove only the AWS-GCP connection
tofu destroy -target=module.conn_aws_gcp -auto-approve
# Success → delete conn-aws-gcp-main.tf, conn-aws-gcp-output.tf
```

**Scenario 2: Remove Multiple Connections Simultaneously**

```bash
# Remove AWS-GCP and AWS-Azure connections simultaneously
tofu destroy \
  -target=module.conn_aws_gcp \
  -target=module.conn_aws_azure \
  -auto-approve
# Success → delete corresponding conn files
```

**Scenario 3: Remove All Connections + Gateway for a Specific CSP**

```bash
# Remove everything related to AWS (connection → gateway order)
# Step 1: Destroy all AWS-related connection modules first
tofu destroy \
  -target=module.conn_aws_azure \
  -target=module.conn_aws_gcp \
  -auto-approve
# Success → delete conn-aws-azure/gcp files + tofu init

# Step 2: Destroy AWS gateway resources
tofu destroy -target=aws_vpn_gateway.vpn_gw -auto-approve
# (aws_vpn_gateway_route_propagation.main is auto-deleted due to VPN GW dependency)
# Success → delete aws-vpn-gw.tf, aws-output.tf, aws-provider.tf + tofu init
```

#### Partial Failure Recovery Strategy

Targeted Destroy can also experience partial failures. However, since `.tf` files still exist, recovery is much easier:

| Situation              | Delete files then apply                      | Targeted Destroy                |
| ---------------------- | -------------------------------------------- | ------------------------------- |
| Partial failure        | No .tf, resources remain in state → orphaned | **.tf exists, retry possible**  |
| CSP temporary outage   | Manual recovery needed                       | **Just retry**                  |
| Dependency order issue | Incomplete dependency graph                  | **Full graph ensures ordering** |
| State inconsistency    | refresh + manual intervention                | **Resolved with refresh only**  |

```
1st recovery: Re-run tofu destroy -target=module.conn_xxx (automatic)
2nd recovery: tofu refresh → re-run tofu destroy -target=... (automatic)
3rd recovery: tofu state rm + manual deletion from CSP console (semi-automatic, last resort)
```

### 2.4. Full Destroy Strategy: Phased Destroy

#### Problem Definition

In Option D, Gateways and Connections are managed with **separate lifecycles** within the same terrarium. Individual Connection removal is safely handled by Targeted Destroy, but **destroying all infrastructure at once** (`DELETE /tr/{trId}/vpn/site-to-site/actions/destroy`) can cause dependency issues.

Connection modules directly reference Gateway resources:

```hcl
# conn-aws-azure-main.tf
module "conn_aws_azure" {
  aws_vpn_gateway_id               = aws_vpn_gateway.vpn_gw.id                  # ← AWS GW reference
  azure_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id   # ← Azure GW reference
}
```

OpenTofu by default destroys in reverse dependency graph order, so Connection → Gateway order must be maintained. However, problems arise in the following situations:

| Situation                            | Problem                                                                                                               | Trigger Condition        |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| **CSP API ordering race**            | CSP has internal additional dependencies (e.g., attempting VGW deletion before AWS VPN Connection deletion completes) | CSP API async processing |
| **Parallel deletion race condition** | OpenTofu deletes independent connection modules in parallel while simultaneously accessing shared gateways            | 3+ CSP configuration     |
| **Partial failure cascade**          | One connection destroy failure → that gateway cannot be destroyed → affects other connections too                     | CSP temporary outage     |

```
Risk scenario (3-CSP configuration: AWS + Azure + GCP):

  tofu destroy (full)
    ├── module.conn_aws_azure destroy ← Success ✅
    ├── module.conn_azure_gcp destroy ← GCP tunnel deletion failed ❌
    ├── module.conn_aws_gcp   destroy ← Success ✅
    │
    ├── aws_vpn_gateway.vpn_gw destroy ← Success ✅ (all AWS connections deleted)
    ├── azurerm_virtual_network_gateway.vpn_gw destroy ← Failed ❌
    │     (Azure resources from conn_azure_gcp still remain, cannot delete)
    └── google_compute_ha_vpn_gateway.vpn_gw destroy ← Failed ❌
          (GCP tunnels from conn_azure_gcp still remain, cannot delete)

  Result: Only AWS resources deleted, Azure/GCP left in partial state
```

#### Solution: Phased Destroy

Execute full destroy not as a single `tofu destroy`, but in **Connection → Gateway** phases.

```
Phased Destroy flow:

  Phase 1: Targeted Destroy all Connection modules
    tofu destroy -target=module.conn_aws_azure -auto-approve
    tofu destroy -target=module.conn_azure_gcp -auto-approve
    tofu destroy -target=module.conn_aws_gcp   -auto-approve
    → All connection resources destroyed

  Phase 2: Full Destroy of remaining Gateway resources
    tofu destroy -auto-approve
    → Only Gateway, Route Propagation, Provider resources remain, safe to delete

  Phase 3: Workspace cleanup
    Delete .tf files and state files (EmptyOut)
```

#### Advantages of Phased Destroy

| Item                     | Single tofu destroy                           | Phased Destroy                                         |
| ------------------------ | --------------------------------------------- | ------------------------------------------------------ |
| Deletion order control   | Depends on OpenTofu dependency graph          | **Explicit order guaranteed**                          |
| Partial failure response | Full failure, tangled state on retry possible | **Independent retry per Phase**                        |
| Parallel deletion race   | OpenTofu parallelizes at its own discretion   | **Sequential execution prevents races**                |
| Error diagnosis          | Hard to identify which resource failed        | **Per-Phase/Connection error tracking possible**       |
| Gateway protection       | Gateway cascade-fails on Connection failure   | **Gateway deleted only after all Connections succeed** |

#### Handler Pseudocode: destroySiteToSiteVpn Improvement

```go
func destroySiteToSiteVpn(trId, reqId string) (model.Response, error) {

    // ──────────────────────────────────────────────
    // Phase 1: Targeted Destroy all Connection modules
    // ──────────────────────────────────────────────
    connPairs := getActiveConnectionPairs(trId) // scan conn-*.tf files in workspace
    for _, pair := range connPairs {
        targetModule := fmt.Sprintf("module.conn_%s", strings.ReplaceAll(pair, "-", "_"))
        _, err := terrarium.DestroyTarget(trId, reqId, targetModule)
        if err != nil {
            log.Error().Err(err).Msgf("Phase 1: failed to destroy connection %s", pair)
            // Continue trying remaining connections even if one fails
            // (independent connections don't affect each other)
            continue
        }
        // Delete .tf files for successfully destroyed connections
        removeConnFiles(trId, pair)
    }

    // Phase 1 failure check: cannot delete Gateways if connections remain
    remainingConns := getActiveConnectionPairs(trId)
    if len(remainingConns) > 0 {
        return emptyRes, fmt.Errorf(
            "Phase 1 incomplete: %d connections remain (%v), retry needed before gateway destroy",
            len(remainingConns), remainingConns,
        )
    }

    // ──────────────────────────────────────────────
    // Phase 2: Full Destroy of remaining Gateway resources
    // ──────────────────────────────────────────────
    ret, err := terrarium.Destroy(trId, reqId)
    if err != nil {
        log.Error().Err(err).Msg("Phase 2: failed to destroy gateways")
        return emptyRes, err
    }

    return model.Response{Success: true, Message: ret}, nil
}
```

#### getActiveConnectionPairs Utility

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

#### Phase 1 Failure Retry Strategy

When some connection destroys fail in Phase 1, Phase 3 is not reached. This is intentional to protect gateways:

```
On Phase 1 partial failure:
  conn_aws_azure  destroy → Success ✅ → delete .tf
  conn_azure_gcp  destroy → Failed ❌ → keep .tf (retry possible)
  conn_aws_gcp    destroy → Success ✅ → delete .tf

  → Phase 2/3 blocked
  → Error response: "1 connection(s) remain, retry needed"
  → When user retries, only conn_azure_gcp is reattempted
  → On success, proceed to Phase 2/3
```

Core principle of this approach: **Never delete Gateways until all Connections have been destroyed.**

#### Phased Destroy Invocation in Full Destroy API

```
DELETE /tr/{trId}/vpn/site-to-site/actions/destroy
→ Internal behavior:
  Phase 1: Get active connection pair list → Targeted Destroy each
  Phase 2: tofu destroy (gateway + route propagation + remaining)
  → On success: workspace cleanup via EmptyOut
```

#### Compatibility with Existing Code

Comparison with current `destroySiteToSiteVpn` handler operations:

```go
// Current (2-CSP only)
terrarium.Destroy(trId, reqId)  // full destroy

// After change (N-CSP, Phased Destroy)
Phase 1: for each conn pair → DestroyTarget(targetModule)  // new
Phase 2: Destroy(trId, reqId)                               // existing, unchanged
```

The only change point is the addition of Phase 1; Phase 2 reuses the existing `Destroy` logic as-is.

### 2.5. Working Directory Structure (at Runtime)

`CopyFiles` copies files flat, and `CopyDir` copies directories recursively. The actual working directory looks like:

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
└── modules/                        # Module source code (recursively copied via CopyDir)
    ├── conn-aws-azure/
    ├── conn-azure-gcp/
    └── conn-aws-gcp/
```

### 2.6. API Design

#### Design Principles

- **Provide bulk creation/deletion as the primary feature** (Primary API)
- Incremental Connection addition/removal as optional extension (Optional API)
- Compatible with existing site-to-site API patterns

#### Primary API: Full-Mesh Bulk Creation/Deletion

When users specify N CSPs, all Gateways + all Connections ($\binom{N}{2}$ pairs) are bulk created/deleted:

```
# Bulk creation (step-by-step execution)
POST   /tr/{trId}/vpn/site-to-site/actions/init      # N-CSP initial configuration (2+ CSPs)
POST   /tr/{trId}/vpn/site-to-site/actions/plan       # Plan
POST   /tr/{trId}/vpn/site-to-site/actions/apply      # Apply
GET    /tr/{trId}/vpn/site-to-site/actions/output      # Information query

# Bulk deletion (Phased Destroy: Connection → Gateway order)
DELETE /tr/{trId}/vpn/site-to-site/actions/destroy     # Full destroy
DELETE /tr/{trId}/vpn/site-to-site/actions/emptyout    # Workspace cleanup
```

cb-tumblebug-friendly high-level API:

```
# Full VPN creation (internally runs init → plan → apply in sequence)
POST /tr/{trId}/vpn/site-to-site
Body: { "vpn_config": { "aws": {...}, "azure": {...}, "gcp": {...} } }

# VPN query
GET /tr/{trId}/vpn/site-to-site?detail=refined

# Full VPN deletion (internally runs Phased Destroy → EmptyOut)
DELETE /tr/{trId}/vpn/site-to-site
```

#### Optional API: Incremental Connection Management

Extension feature for adding CSPs to existing VPN environments or removing specific Connections:

```
# Connection addition (create all pairs between new CSP and existing CSPs)
POST   /tr/{trId}/vpn/site-to-site/connections/actions/add-and-init
       # Body: { "add_csp": { "gcp": { region: "...", ... } } }
POST   /tr/{trId}/vpn/site-to-site/connections/actions/plan
POST   /tr/{trId}/vpn/site-to-site/connections/actions/apply

# Connection removal (Targeted Destroy)
DELETE /tr/{trId}/vpn/site-to-site/connections/{pair}
       # Warning: Full-Mesh integrity may be broken (Transit Routing not supported)
```

> **Warning**: Removing individual Connections breaks Full-Mesh, which may make communication between some CSPs impossible (see §2.11). CSP-level removal is recommended over individual Connection removal.

#### CSP Constraint-based Validation

Pre-validate CSP-specific constraints at the API level:

| CSP         | Constraint                  | Limit                         | Full-Mesh Impact                                       |
| ----------- | --------------------------- | ----------------------------- | ------------------------------------------------------ |
| **AWS**     | Max VPN Connections per VGW | 10                            | 2 Connections per CSP × max 5 remote CSPs = 10 (limit) |
| **Azure**   | APIPA address range         | 169.254.21.0 – 169.254.22.255 | 6 CSPs supported via per-CSP CIDR allocation           |
| **Azure**   | Max Connections per VPN GW  | Varies by SKU (VpnGw1: 30)    | Sufficient                                             |
| **GCP**     | HA VPN Gateway interfaces   | Fixed at 2                    | Handled via External GW configuration                  |
| **Alibaba** | VPN Gateway bandwidth       | Minimum 10Mbps                | Shared bandwidth                                       |

```go
// Validation pseudocode
func validateCSPConstraints(csps []string) error {
    // AWS VGW: max 10 VPN connections
    // Assuming 2 connections per CSP → max 5 remote CSPs connectable
    if containsAWS(csps) && len(csps)-1 > 5 {
        return fmt.Errorf("AWS VGW supports max 10 connections (5 remote CSPs × 2), requested: %d", len(csps)-1)
    }
    return nil
}
```

### 2.7. User Workflows

#### Scenario 1: Initial 3-CSP Configuration (AWS + Azure + GCP)

```
Step 1: Init (all gateways + connections at once)
  POST /tr/tr01/vpn/site-to-site/actions/init
  Body: {
    "vpn_config": {
      "terrarium_id": "tr01",
      "aws":   { "region": "ap-northeast-2", "vpc_id": "...", ... },
      "azure": { "region": "koreacentral", ... },
      "gcp":   { "region": "asia-northeast3", ... }
    }
  }
  → 3 CSP gateways + 3 conn pairs (aws-azure, aws-gcp, azure-gcp)

Step 2: Plan → Apply
  POST /tr/tr01/vpn/site-to-site/actions/plan
  POST /tr/tr01/vpn/site-to-site/actions/apply
```

#### Scenario 2: Add Alibaba to Existing Environment

```
Step 1: Add connection
  POST /tr/tr01/vpn/site-to-site/connections/actions/add-and-init
  Body: {
    "add_csp": {
      "alibaba": { "region": "ap-northeast-2", ... }
    }
  }
  → Copy alibaba gateway files
  → Copy conn-alibaba-aws, conn-alibaba-azure, conn-alibaba-gcp files
  → Update tfvars
  → tofu init

Step 2: Plan → Apply
  POST /tr/tr01/vpn/site-to-site/connections/actions/plan
  POST /tr/tr01/vpn/site-to-site/connections/actions/apply
  → Create Alibaba VPN Gateway + 3 new connections
  → Existing AWS, Azure, GCP gateways and connections remain unchanged
```

#### Scenario 3: Remove Only the AWS-GCP Connection

```
Step 1: Remove connection via Targeted Destroy
  DELETE /tr/tr01/vpn/site-to-site/connections/aws-gcp
  → Internal behavior:
    1. tofu destroy -target=module.conn_aws_gcp -auto-approve
    2. Success → delete conn-aws-gcp-main.tf, conn-aws-gcp-output.tf
    3. tofu init (clean up modules)
  → AWS gateway, GCP gateway, other connections remain
```

#### Scenario 4: Fully Remove AWS (gateway + all AWS connections)

```
Step 1: Targeted Destroy all AWS-related connections
  DELETE /tr/tr01/vpn/site-to-site/connections/aws-azure
  DELETE /tr/tr01/vpn/site-to-site/connections/aws-gcp
  → Internal behavior:
    Each runs tofu destroy -target=module.conn_aws_azure, conn_aws_gcp
    → Success → delete conn files → tofu init

Step 2: Remove AWS gateway
  # Or use bulk removal API:
  # DELETE /tr/tr01/vpn/site-to-site/csp/aws
  → Internal behavior:
    tofu destroy -target=aws_vpn_gateway.vpn_gw -auto-approve
    (aws_vpn_gateway_route_propagation.main auto-deleted due to VPN GW dependency)
    → Success → delete aws-vpn-gw.tf, aws-output.tf, aws-provider.tf
    → tofu init

Step 3: Verify results
  → Azure, GCP gateways + azure-gcp connection remain
```

### 2.8. Handler Changes

#### 2.8.1. initSiteToSiteVpn Changes

```go
// Change: Allow 2 or more CSPs (current: len(providers) != 2)
if len(providers) < 2 {
    err := fmt.Errorf("site-to-site VPN requires at least 2 CSPs, got %d", len(providers))
    ...
}

// Change: Copy conn files for all CSP pairs
// (current: processes only a single pair — providerPair := fmt.Sprintf("%s-%s", providers[0], providers[1]))
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

#### 2.8.2. New addConnectionHandler

```go
func addConnectionInit(c echo.Context) (model.Response, error) {
    trId := c.Param("trId")

    // 1. Load current terrarium info
    trInfo, exists, err := terrarium.GetInfo(trId)

    // 2. Receive new CSP configuration
    req := new(model.AddConnectionRequest)
    c.Bind(req)
    newCsp := req.AddCsp  // e.g., "gcp"

    // 3. Add new CSP to existing providers list
    existingProviders := trInfo.Providers
    allProviders := append(existingProviders, newCsp)
    sort.Strings(allProviders)

    // 4. Copy new CSP gateway files (CopyFiles — flat)
    cspDir := projectRoot + "/templates/" + enrichments + "/" + newCsp
    tfutil.CopyFiles(cspDir, workingDir)

    // 5. Copy conn files for all pairs of new CSP × existing CSPs (CopyFiles — flat)
    for _, existing := range existingProviders {
        pair := sortedPair(existing, newCsp) // alphabetically sorted
        connDir := projectRoot + "/templates/" + enrichments + "/conn-" + pair
        tfutil.CopyFiles(connDir, workingDir)
    }

    // 6. Copy new module sources (CopyDir — recursive)
    srcModuleDir := templateTfsPath + "/modules"
    dstModuleDir := workingDir + "/modules"
    tfutil.CopyDir(srcModuleDir, dstModuleDir)

    // 7. Update tfvars (merge new CSP config into existing config)
    existingTfVars := loadTfVars(workingDir)
    existingTfVars.VpnConfig.Gcp = req.GcpConfig  // example
    terrarium.SaveTfVars(trId, enrichments, existingTfVars)

    // 8. Update terrarium info
    trInfo.Providers = allProviders
    terrarium.UpdateInfo(trInfo)

    // 9. tofu init
    ret, err := terrarium.Init(trId, reqId)
    // ...
}
```

#### 2.8.3. New removeConnectionHandler (Targeted Destroy)

```go
func removeConnection(c echo.Context) (model.Response, error) {
    trId := c.Param("trId")
    pair := c.Param("pair")  // e.g., "aws-gcp"
    reqId := c.Response().Header().Get("X-Request-Id")

    workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments

    // Step 1: Targeted Destroy (destroy resources only, files untouched)
    targetModule := fmt.Sprintf("module.conn_%s", strings.ReplaceAll(pair, "-", "_"))
    _, err := terrarium.DestroyTarget(trId, reqId, targetModule)
    if err != nil {
        // .tf files remain, no recovery needed, just retry
        log.Error().Err(err).Msgf("targeted destroy failed for %s, retry possible", pair)
        return model.Response{}, fmt.Errorf("failed to destroy connection %s: %w", pair, err)
    }

    // Step 2: Destroy succeeded → delete .tf files
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-main.tf"))
    os.Remove(filepath.Join(workingDir, "conn-"+pair+"-output.tf"))

    // Step 3: Re-init (clean up module references)
    terrarium.Init(trId, reqId)

    // Step 4: Update terrarium info
    // (remove this pair, consider removing CSP from providers if no more connections)

    return model.Response{Success: true}, nil
}
```

#### 2.8.4. outputSiteToSiteVpn Changes

```go
// Change: Collect Gateway info + Connection info separately
// (current: queries single "{csp}_vpn_info" output)

// Gateway info: query "{csp}_vpn_gateway_info" output
for _, provider := range providers {
    targetObject := fmt.Sprintf("%s_vpn_gateway_info", provider)
    gatewayInfo, _ := terrarium.Output(trId, reqId, targetObject, "-json")
    mergeResourceInfo(result, gatewayInfo)
}

// Connection info: query "conn_{pair}_info" output
for i := 0; i < len(providers); i++ {
    for j := i + 1; j < len(providers); j++ {
        pair := fmt.Sprintf("%s_%s", providers[i], providers[j])
        targetObject := fmt.Sprintf("conn_%s_info", pair)
        connInfo, err := terrarium.Output(trId, reqId, targetObject, "-json")
        if err != nil {
            continue  // skip if no connection for this pair
        }
        mergeResourceInfo(result, connInfo)
    }
}
```

### 2.9. Template Changes Summary

| File                                | Current                                               | After Change                                                        |
| ----------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------- |
| `aws/aws-output.tf`                 | `aws_vpn_info` (includes conn references)             | `aws_vpn_gateway_info` (Gateway info only, conn references removed) |
| `azure/azure-output.tf`             | `azure_vpn_info` (conn references commented out)      | `azure_vpn_gateway_info` (Gateway info only, name standardized)     |
| `gcp/gcp-output.tf`                 | `gcp_vpn_gateway_info` (already correct)              | No change                                                           |
| `alibaba/alibaba-output.tf`         | 5 individual outputs (`alibaba_vpn_gateway_id`, etc.) | `alibaba_vpn_gateway_info` (consolidated, standardized)             |
| `conn-{pair}/conn-{pair}-output.tf` | `{csp}_vpn_conn_info` (collision possible)            | `conn_{pair}_info` (pair-unique name)                               |

### 2.10. Pros and Cons Analysis

#### Pros

1. **Single Terrarium**: No cross-state references between Terrariums. Gateways are directly referenced within the same state
2. **Incremental composition**: Connections can be added/removed one at a time. No need to rebuild everything
3. **Safe connection removal**: Targeted Destroy (`tofu destroy -target`) → delete files only on success → retry on failure
4. **Low implementation complexity**: Extends existing site-to-site code. No new architecture patterns required
5. **User-friendly**: Upper systems only need to call "Add CSP" / "Remove Connection" APIs
6. **Existing module reuse**: conn-aws-azure, conn-azure-gcp, conn-alibaba-azure modules used as-is

#### Cons

1. **State size**: All N-CSPs in a single state → state grows as CSP count increases
2. **Apply scope**: `tofu plan/apply` scans entire state (however, unchanged resources are no-change)
3. **Partial failure recovery**: Recovery strategy needed when some CSP resources fail to create in a single state
4. **AWS VGW 10 Connection limit**: Quota exceeded possible with Full-Mesh 6+ CSPs (common constraint across all approaches)

#### Risk Analysis

| Risk Factor         | Impact | Likelihood | Mitigation                                                                       |
| ------------------- | ------ | ---------- | -------------------------------------------------------------------------------- |
| State size increase | Low    | High       | Even with all 7 CSPs connected, ~100–200 resources, manageable                   |
| Apply time increase | Medium | Medium     | Unchanged resources only refresh; actual changes only on added/removed resources |
| Partial failure     | High   | Low        | Failed resources retry on next apply; state accurately reflects current status   |
| Quota exceeded      | High   | Low        | Pre-validation at API level; AWS VGW max 5 CSPs simultaneous connection limit    |

### 2.11. Transit Routing Analysis

#### Problem Definition

When building Full-Mesh VPN within an MCI (Multi-Cloud Infrastructure), **all VMs across all CSPs must be able to communicate with VMs in every other CSP**. This requires each CSP's route table to hold routes to all remote CSPs' CIDRs.

Transit routing refers to **forwarding traffic through an intermediate CSP**, such as CSP A → CSP B → CSP C. If CSP VPN Gateways do not support transit routing, all CSP pairs must be directly connected.

#### CSP VPN Gateway Routing Behavior

Codebase analysis shows that **all CSP VPN Gateways do not re-advertise routes learned from other BGP peers:**

| CSP                  | Routing Method                                             | Route Advertisement Scope   | Re-advertisement |
| -------------------- | ---------------------------------------------------------- | --------------------------- | ---------------- |
| **AWS VGW**          | BGP + `aws_vpn_gateway_route_propagation`                  | Own VPC CIDR only           | **NO**           |
| **Azure VPN GW**     | BGP (`enable_bgp = true`)                                  | Own VNet CIDR only          | **NO**           |
| **GCP Cloud Router** | BGP (`advertised_groups = ["ALL_SUBNETS"]`)                | Own VPC subnets only        | **NO**           |
| **Alibaba**          | BGP (`enable_tunnels_bgp = true`) + explicit route entries | Own VPC CIDR only           | **NO**           |
| **Tencent**          | Static (`static_routes_only = true`)                       | Explicit configuration only | N/A              |
| **IBM**              | Static (`static_routes_only = true`)                       | Explicit configuration only | N/A              |

> **Note**: GCP Cloud Router's `ALL_SUBNETS` means "all subnets in the GCP VPC" and does not include routes learned from other BGP peers.

#### Conclusion: Transit Routing Is Unnecessary in Full-Mesh

**In a Full-Mesh topology, every CSP pair has a direct tunnel, so Transit Routing is not needed.**

```
Full-Mesh 3-CSP (AWS, Azure, GCP) example:

AWS route table:                          ┌─────────┐
  10.2.0.0/16 → AWS-Azure tunnel (BGP)   │  AWS    │──── Azure
  10.3.0.0/16 → AWS-GCP tunnel (BGP)     │10.1.0.0 │
                                          └────┬────┘
Azure route table:                             │
  10.1.0.0/16 → Azure-AWS tunnel (BGP)        │
  10.3.0.0/16 → Azure-GCP tunnel (BGP)   ┌────┴────┐
                                          │  GCP    │
GCP route table:                          │10.3.0.0 │
  10.1.0.0/16 → GCP-AWS tunnel (BGP)     └─────────┘
  10.2.0.0/16 → GCP-Azure tunnel (BGP)

→ All destinations reachable via direct tunnels ✅
→ Transit routing unnecessary ✅
```

Each CSP learns all remote CSP CIDRs through N-1 direct VPN connections:

- **BGP CSPs** (AWS, Azure, GCP, Alibaba): Automatically learned via BGP sessions on direct connections
- **Static CSPs** (Tencent, IBM): Each connection module explicitly sets CIDR routes for that pair

#### Risk of Partial Mesh

In a Partial Mesh where only some pairs are connected, Transit Routing would be needed, but since CSP VPN Gateways **do not support it, communication is impossible**:

```
Partial Mesh (AWS ↔ Azure ↔ GCP only, no direct AWS ↔ GCP connection):
  AWS VM → GCP VM: AWS → Azure tunnel → Azure VPN GW → ???
  → Azure VPN GW does not forward AWS→GCP traffic to the GCP tunnel ❌
  → AWS→GCP communication impossible ❌
```

Therefore, **Full-Mesh VPN must be truly Full-Mesh**. Option D's design guarantees this by automatically creating all $\binom{N}{2}$ pairs when N CSPs are selected.

#### Considerations for Static Routing CSP Connection Module Development

Currently in `aws-to-site` templates, Static routing CSPs (Tencent, IBM) set only a single remote CIDR:

```hcl
# Current (aws-to-site): single remote CIDR
resource "tencentcloud_vpn_gateway_route" "route" {
  destination_cidr_block = var.aws_vpc_cidr_block  # ← only AWS CIDR
}
```

In Full-Mesh `site-to-site` modules, **each connection module handles only the remote CIDR for that pair**, so the structure is identical:

```hcl
# conn-aws-tencent module: Set Tencent → AWS CIDR route
resource "tencentcloud_vpn_gateway_route" "to_aws" {
  destination_cidr_block = var.aws_vpc_cidr  # AWS CIDR
}

# conn-azure-tencent module: Set Tencent → Azure CIDR route
resource "tencentcloud_vpn_gateway_route" "to_azure" {
  destination_cidr_block = var.azure_vnet_cidr  # Azure CIDR
}
# → N-1 connection modules each handle 1 remote CIDR → collectively cover all CIDRs
```

### 2.12. Dynamic/Static Routing Hybrid Analysis

#### Background

Among 7 CSPs, BGP-capable CSPs (AWS, Azure, GCP, Alibaba) and Static Routing-only CSPs (Tencent, IBM, DCS) coexist. To build Full-Mesh, **hybrid configurations where BGP Connections and Static Connections coexist on a single VPN Gateway** are essential.

#### Per-CSP Hybrid Support

| CSP              | Routing config level                                                            | Hybrid possible | Rationale                                                                                                                   |
| ---------------- | ------------------------------------------------------------------------------- | --------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **AWS VGW**      | Connection level (`static_routes_only` on `aws_vpn_connection`)                 | **Yes**         | Confirmed in `aws-to-site` templates: same VGW supports BGP (GCP, Azure, Alibaba) + Static (Tencent, IBM, DCS) coexistence  |
| **Azure VPN GW** | Connection level (`enable_bgp` on `azurerm_virtual_network_gateway_connection`) | **Yes**         | Gateway's `enable_bgp = true` declares BGP "capability"; each Connection can set `enable_bgp = false` for Static connection |
| **GCP HA VPN**   | Gateway/Router level (Cloud Router BGP mandatory)                               | **No**          | GCP HA VPN requires BGP sessions on all tunnels. No Static-only Connection concept                                          |
| **Alibaba**      | Connection level (`enable_tunnels_bgp` on `alicloud_vpn_connection`)            | **Yes**         | Per-connection BGP/Static independent configuration possible                                                                |
| **Tencent**      | Fixed Static (`route_type = "StaticRoute"`)                                     | N/A             | Always the Static side                                                                                                      |
| **IBM**          | Fixed Static (`mode = "route"`)                                                 | N/A             | Always the Static side                                                                                                      |
| **DCS**          | Fixed Static (VPNaaS Endpoint Group)                                            | N/A             | Always the Static side                                                                                                      |

> **Key finding**: AWS, Azure, and Alibaba support hybrid Routing, but **GCP cannot**.

#### Full-Mesh Routing Matrix

| From \ To   | AWS    | Azure  | GCP     | Alibaba | Tencent | IBM     | DCS     |
| ----------- | ------ | ------ | ------- | ------- | ------- | ------- | ------- |
| **AWS**     | -      | BGP    | BGP     | BGP     | Static  | Static  | Static  |
| **Azure**   | BGP    | -      | BGP     | BGP     | Static  | Static  | Static  |
| **GCP**     | BGP    | BGP    | -       | BGP     | **N/A** | **N/A** | **N/A** |
| **Alibaba** | BGP    | BGP    | BGP     | -       | Static  | Static  | Static  |
| **Tencent** | Static | Static | **N/A** | Static  | -       | Static  | Static  |
| **IBM**     | Static | Static | **N/A** | Static  | Static  | -       | Static  |
| **DCS**     | Static | Static | **N/A** | Static  | Static  | Static  | -       |

- **BGP**: Both sides support BGP → Dynamic Routing
- **Static**: One or both sides do not support BGP → Static Routing (both sides Static)
- **N/A**: GCP HA VPN forces BGP but peer does not support BGP → direct connection impossible

#### Conclusion

1. **Hybrid Routing itself is feasible**: Routing method is determined at the Connection level, so BGP + Static coexistence on the same Gateway is possible (verified for AWS, Azure, Alibaba)
2. **GCP is the Full-Mesh bottleneck**: GCP ↔ {Tencent, IBM, DCS} — 3 pairs cannot be directly connected
3. **7-CSP complete Full-Mesh is impossible**: 3 of $\binom{7}{2} = 21$ pairs cannot be connected
4. **Feasible configuration scope**:
   - BGP 4-CSP Full-Mesh (AWS, Azure, GCP, Alibaba): Complete Full-Mesh possible
   - 6-CSP Full-Mesh excluding GCP (AWS, Azure, Alibaba, Tencent, IBM, DCS): Hybrid Full-Mesh possible
   - 7-CSP: Partial Mesh excluding GCP ↔ Static CSP 3 pairs (18/21 pairs)

---

## 3. Implementation Roadmap

### 3.1. Phase 0: Template Refactoring + Remaining CSP Pair Module Development (Short-term, 1–2 months)

#### 0-1. Output Structure Refactoring (1 week)

This is the essential prerequisite for Option D:

1. **Separate gateway output**: Remove connection module references from `aws-output.tf` and rename to `aws_vpn_gateway_info`
2. **Standardize gateway output**: Consolidate `alibaba-output.tf` individual outputs to `alibaba_vpn_gateway_info`, rename `azure-output.tf` to `azure_vpn_gateway_info`
3. **Unique connection output names**: Change `conn-{pair}/conn-{pair}-output.tf` to `conn_{pair}_info` format
4. **Handler changes**: Collect gateway info and connection info separately in `outputSiteToSiteVpn()` and merge

#### 0-2. Remaining Connection Module Development (1–2 months)

Currently implemented pairs (Azure-centric):

- ✅ conn-aws-azure
- ✅ conn-azure-gcp
- ✅ conn-alibaba-azure

Pairs requiring development (12 total):

| #   | Pair                 | BGP       | Difficulty  | Priority |
| --- | -------------------- | --------- | ----------- | -------- |
| 1   | conn-alibaba-aws     | ✅        | Medium      | High     |
| 2   | conn-aws-gcp         | ✅        | Medium      | High     |
| 3   | conn-aws-ibm         | ❌ Static | Medium      | Medium   |
| 4   | conn-aws-tencent     | ❌ Static | Medium      | Medium   |
| 5   | conn-alibaba-gcp     | ✅        | Medium      | Medium   |
| 6   | conn-azure-ibm       | ❌ Static | Medium-High | Medium   |
| 7   | conn-azure-tencent   | ❌ Static | Medium-High | Medium   |
| 8   | conn-alibaba-ibm     | ❌ Static | Medium      | Low      |
| 9   | conn-alibaba-tencent | ❌ Static | Medium      | Low      |
| 10  | conn-ibm-tencent     | ❌ Static | Medium      | Low      |
| 11  | conn-alibaba-dcs     | ❌ Static | Medium      | Low      |
| 12  | conn-aws-dcs         | ❌ Static | Medium      | Low      |

Infeasible pairs (GCP ↔ Static CSP, see §2.12):

| #   | Pair             | Reason                                                 |
| --- | ---------------- | ------------------------------------------------------ |
| -   | conn-gcp-ibm     | GCP HA VPN requires BGP ↔ IBM does not support BGP     |
| -   | conn-gcp-tencent | GCP HA VPN requires BGP ↔ Tencent does not support BGP |
| -   | conn-dcs-gcp     | GCP HA VPN requires BGP ↔ DCS does not support BGP     |

#### Recommended Development Order

1. **conn-alibaba-aws, conn-aws-gcp** (BGP, high priority)
2. **conn-aws-ibm, conn-aws-tencent** (Static routing, reference aws-to-site modules)
3. **conn-alibaba-gcp** (BGP, reference alibaba-azure + azure-gcp patterns)
4. **conn-azure-ibm, conn-azure-tencent** (Azure APIPA + Static routing)
5. **Remaining pairs** (based on usage frequency)

#### Development Process (per pair)

1. **Verify in examples/**: Write CSP official documentation VPN connection examples in `examples/` and manually test
2. **Develop templates/ module**: Modularize verified .tf files into `templates/vpn/site-to-site/modules/conn-{csp1}-{csp2}/`
3. **Develop implementation layer**: Create module invocation files in `templates/vpn/site-to-site/conn-{csp1}-{csp2}/`
4. **Standardize output**: Write output in `conn_{pair}_info` format

### 3.2. Phase 1: N-CSP Bulk Creation/Deletion API (Short-term, 0.5–1 month) ★ Core

After Phase 0 refactoring and module preparation, **implement Full-Mesh bulk creation/deletion as the primary feature**:

1. **Handler modification**: `len(providers) != 2` → `len(providers) < 2` (N-CSP support)
2. **Add per-provider-pair conn copy logic** (automatically create all $\binom{N}{2}$ pairs for N CSPs)
3. **Output integration modification**: Separate collection of `{csp}_vpn_gateway_info` + `conn_{pair}_info` → merge
4. **Implement Phased Destroy**: Safe full deletion in Connection → Gateway order (§2.4)
5. **Implement CSP Validation**: Pre-validation of AWS VGW 10 Connection limit, etc. (§2.6)
6. **Add terrarium.DestroyTarget function**: Support `-target`-based Phased Destroy Phase 1

### 3.3. Phase 2: Stabilization and Incremental Connection Management (Medium-term, 1–2 months)

1. **Incremental Connection API (Optional)**: Connection add (`add-and-init`), remove (Targeted Destroy) endpoints
2. **CSP-level removal API**: Targeted Destroy of all connections + gateway related to a specific CSP at once
3. **Enhanced status queries**: Active connection pair list, per-pair status queries
4. **Error recovery mechanisms**: Automatic retry on partial failure, state consistency verification

> **Note**: The Incremental Connection API (add/remove) is an optional feature. Phase 1's bulk creation/deletion alone sufficiently supports the Tumblebug MCI-based Full-Mesh VPN scenario. Caution is needed when removing individual Connections as it may break Full-Mesh integrity (see §2.11).

### 3.4. Phase 3: Monitoring and Advanced Features (Long-term)

- VPN tunnel status monitoring and Health Check integration
- Connection topology visualization
- Automatic reconnection/recovery mechanisms
- Bandwidth optimization and routing metric management

### 3.5. Immediately Actionable Approach

**Step 1: Output Structure Refactoring (Top Priority)**

```hcl
# aws/aws-output.tf (before)
output "aws_vpn_info" {
  value = {
    aws = merge(
      { vpn_gateway = { ... } },
      try(module.conn_aws_azure.aws_vpn_conn_info, {})  # ← remove!
    )
  }
}

# aws/aws-output.tf (after)
output "aws_vpn_gateway_info" {    # ← name changed: gateway_info
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

**Step 2: Remaining Connection Module Development**

Refactor existing `aws-to-site/modules/` to `site-to-site/modules/conn-{pair}/` pattern:

| aws-to-site module        | site-to-site module conversion     | Differences                                               |
| ------------------------- | ---------------------------------- | --------------------------------------------------------- |
| `modules/gcp/main.tf`     | `modules/conn-aws-gcp/main.tf`     | AWS resources become variables (gateway_id, vpc_id, etc.) |
| `modules/alibaba/main.tf` | `modules/conn-alibaba-aws/main.tf` | Same                                                      |
| `modules/tencent/main.tf` | `modules/conn-aws-tencent/main.tf` | Same                                                      |
| `modules/ibm/main.tf`     | `modules/conn-aws-ibm/main.tf`     | Same                                                      |

**Step 3: Handler Extension and Incremental Connection Management API**

Perform the following changes in `vpn-site-to-site-actions.go`:

1. Change `len(providers) != 2` to `len(providers) < 2`
2. Add logic to copy conn directories for all provider pairs
3. Add incremental Connection add/remove API endpoints
4. Separate collection of `{csp}_vpn_gateway_info` and `conn_{pair}_info` in Output function → merge
5. Add Connection removal handler using `terrarium.DestroyTarget` function

### Constraint Awareness and Validation

Pre-validate CSP characteristics/constraints at the API level when configuring Full-Mesh VPN:

| Constraint                                   | Detail                                   | Impact                                                         | Validation Approach                              |
| -------------------------------------------- | ---------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------ |
| **AWS VGW 10 Connection limit**              | Max 10 VPN Connections per VGW           | 2 Connections per CSP × max 5 remote CSPs = 10 (limit)         | Return error if `len(csps)-1 > 5`                |
| **Azure APIPA range**                        | 169.254.21.0 – 169.254.22.255            | 6 CSPs simultaneously connectable via per-CSP APIPA allocation | CIDR conflict verification                       |
| **BGP ASN uniqueness**                       | Unique ASN required per CSP              | BGP sessions fail on ASN collision                             | Guaranteed via fixed per-CSP ASN                 |
| **Apply time**                               | Simultaneous creation of all CSP VPN GWs | Expected 30–60 minutes                                         | Timeout configuration and progress query support |
| **Full-Mesh mandatory**                      | Transit Routing not supported            | Some CSPs cannot communicate in Partial Mesh                   | Guaranteed by auto-creating all pairs            |
| **GCP ↔ Static CSP connection not possible** | GCP HA VPN requires BGP                  | 3 pairs infeasible in 7-CSP Full-Mesh (§2.12)                  | Exclude Static CSPs when GCP is included         |

---

## 4. New CSP Pair Module Development Reference (conn-aws-gcp Example)

A `site-to-site/modules/conn-aws-gcp/` module is written based on the existing `aws-to-site/modules/gcp/main.tf`.

### Key Difference: Variable Reference Approach

```hcl
# aws-to-site approach: direct resource reference
resource "aws_customer_gateway" "gcp_gw" {
  ip_address = google_compute_ha_vpn_gateway.vpn_gw.vpn_interfaces[count.index].ip_address
  # ↑ Directly references GCP resource in the same state
}

# site-to-site module approach: reference via variable
resource "aws_customer_gateway" "gcp_gw" {
  ip_address = var.gcp_vpn_gateway_addresses[count.index]
  # ↑ Received as variable from the upper layer
}
```

### modules/conn-aws-gcp/variables.tf Example

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

### conn-aws-gcp/conn-aws-gcp-main.tf Example

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

## 5. cb-tumblebug Integration Perspective Analysis

### 5.1. cb-tumblebug's Current VPN Integration Structure

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

#### Key Characteristics

| Item             | Current State                                                                     |
| ---------------- | --------------------------------------------------------------------------------- |
| Supported API    | Uses only `/tr/{trId}/vpn/aws-to-site` (site-to-site API not used)                |
| Hub limitation   | **AWS only** (only AWS exists as key in `supportedCspForVpn`)                     |
| VPN unit         | 1:1 (1 VPN = 1 Terrarium = 1 aws-to-site pair)                                    |
| State management | cb-tumblebug: `Configuring`→`Available`→`Deleting` / mc-terrarium: OpenTofu state |
| ID mapping       | `VpnInfo.Uid` = `TerrariumInfo.Id` (1:1)                                          |
| Resource query   | Extracted from mc-terrarium output → cached in KV store                           |
| Data model       | `VpnInfo.VpnSites[0]` = hub (AWS), `VpnSites[1]` = spoke                          |
| Error recovery   | `?action=retry` parameter support (load existing info from KV and retry)          |

### 5.2. cb-tumblebug Impact Analysis for Option D Integration

#### Scenario A: Continued 1:1 VPN (Simplest)

Even with Option D applied, if cb-tumblebug still manages only 1:1 pair VPNs:

```
Changes needed:
  - mc-terrarium API path change: /vpn/aws-to-site → /vpn/site-to-site
  - Request body change: CreateAwsToSiteVpnRequest → CreateSiteToSiteVpnRequest
  - Output parsing change: {csp}_vpn_info → {csp}_vpn_gateway_info + conn_{pair}_info
  - Can add other hub CSPs to supportedCspForVpn

cb-tumblebug change amount: Medium (API call changes + output parsing)
Complexity: Low
```

#### Scenario B: Multi-pair VPN (Manage N CSPs as one VPN) — The True Benefit of Option D

```
Current (1:1):
  vpn-01: AWS ↔ Azure     (terrarium: tr-vpn01)
  vpn-02: AWS ↔ GCP       (terrarium: tr-vpn02)  ← separate VPN, separate terrarium
  vpn-03: Azure ↔ GCP     (terrarium: tr-vpn03)  ← impossible (Azure hub not supported)

Option D (N:N):
  vpn-01: AWS ↔ Azure ↔ GCP  (terrarium: tr-vpn01, managed entirely in single terrarium)
```

cb-tumblebug changes required:

```
1. Data model change
   Current: VpnInfo.VpnSites = [site1(hub), site2(spoke)]  (fixed 2)
   Change:  VpnInfo.VpnSites = [site1, site2, ... siteN]    (variable N)
            VpnInfo.Connections = [{pair: "aws-azure"}, {pair: "aws-gcp"}, {pair: "azure-gcp"}]

2. API change
   Current: POST /vpn (site1 + site2)
   Change:  POST /vpn (sites: [site1, site2, ..., siteN])
            POST /vpn/{vpnId}/connections (add new site)
            DELETE /vpn/{vpnId}/connections/{pair} (remove connection)

3. mc-terrarium call change
   Current: POST /tr/{trId}/vpn/aws-to-site
   Change:  POST /tr/{trId}/vpn/site-to-site (N CSPs)
            POST /tr/{trId}/vpn/site-to-site/connections (add new CSP)
            DELETE /tr/{trId}/vpn/site-to-site/connections/{pair} (remove via Targeted Destroy)

4. Polling change
   Current: GET /tr/{trId}/vpn/aws-to-site?detail=refined
   Change:  GET /tr/{trId}/vpn/site-to-site?detail=refined
```

### 5.3. cb-tumblebug Integration Ease Assessment

| Assessment Item                 | Option C (GW/Conn Separation)                      | Option D (Incremental Composition)        |
| ------------------------------- | -------------------------------------------------- | ----------------------------------------- |
| cb-tumblebug API change amount  | High (2-stage API for gateway + connection needed) | **Low-Medium** (extends existing pattern) |
| Terrarium ID management         | Complex (multiple GW terrarium + Conn terrariums)  | **Simple** (1 terrarium per VPN)          |
| State model complexity          | High (separate GW state + Conn state tracking)     | **Medium** (VPN state + connection list)  |
| Incremental composition support | Possible but complex                               | **Natural**                               |
| Existing pattern compatibility  | Low (new workflow needed)                          | **High** (extends existing pattern)       |
| Polling pattern                 | 2-stage polling needed for each                    | **1-stage polling** (same as existing)    |
| Error recovery                  | Complex (separate GW/Conn recovery)                | **Simple** (single terrarium recovery)    |

### 5.4. cb-tumblebug Model Change Proposal

```go
// Current model (1:1 pair)
type RestPostVpnRequest struct {
    Name  string       `json:"name"`
    Site1 SiteProperty `json:"site1"`     // fixed 2
    Site2 SiteProperty `json:"site2"`
}

// Proposed model (N CSP support, backward compatible)
type RestPostVpnRequest struct {
    Name  string         `json:"name"`
    // Keep existing fields (backward compatibility)
    Site1 *SiteProperty  `json:"site1,omitempty"`
    Site2 *SiteProperty  `json:"site2,omitempty"`
    // New fields (N CSP support)
    Sites []SiteProperty `json:"sites,omitempty"`
}

// VPN info model extension
type VpnInfo struct {
    ResourceType string          `json:"resourceType"`
    Id           string          `json:"id"`
    Uid          string          `json:"uid"`
    Name         string          `json:"name"`
    Description  string          `json:"description"`
    Status       string          `json:"status"`
    VpnSites     []VpnSiteDetail `json:"vpnSites"`
    // New: active connection list
    Connections  []VpnConnection `json:"connections,omitempty"`
}

type VpnConnection struct {
    Pair   string `json:"pair" example:"aws-azure"`    // Connection pair name
    Status string `json:"status" example:"Available"`  // Individual connection status
}
```

### 5.5. Integration Conclusion

1. **Option D is suitable for cb-tumblebug integration**: N-CSP extension possible while maintaining 1 VPN = 1 Terrarium mapping
2. **Preserves existing integration pattern**: POST (create) → Polling (wait for completion) → GET (result) pattern usable as-is
3. **Gradual migration possible**:
   - Phase 1: Maintain existing aws-to-site API + run site-to-site API in parallel (minimize cb-tumblebug changes)
   - Phase 2: Migrate cb-tumblebug to site-to-site API
   - Phase 3: Integrate connection add/remove API
4. **Integration complexity drastically reduced vs. Option C**: With Gateway/Connection separation, cb-tumblebug would need to manage multiple terrariums, but Option D requires only a single terrarium

---

## 6. Conclusion and Discussion Points

### 6.1. Current State

- aws-to-site: 6 CSP connections complete (Star topology)
- site-to-site: 3 pair modules complete (aws-azure, azure-gcp, alibaba-azure)
- Option C (Gateway/Connection Separation) deferred due to implementation complexity, user complexity, and connection removal difficulty

### 6.2. Option D (Single-Terrarium Incremental Composition) — Design Complete, Implementation Deferred

Option D is a design that resolves the following core problems based on the current site-to-site structure:

1. **Implementation complexity**: Implemented as an extension of existing code. No new architecture patterns needed
2. **User complexity**: Single Terrarium, simple interface with N-CSP bulk creation/deletion API
3. **Safe full deletion**: Phased Destroy (Connection → Gateway order) → retry possible on partial failure
4. **Transit Routing resolution**: Full-Mesh topology directly connects all CSP pairs → Transit unnecessary (§2.11)

However, due to the following constraints, **implementation is deemed premature at this time**:

#### Reasons for Implementation Deferral

1. **GCP ↔ Static CSP direct connection not possible** (§2.12): GCP HA VPN's BGP requirement makes direct connection with Tencent, IBM, DCS impossible. Complete 7-CSP Full-Mesh cannot be achieved
2. **Transit Routing not supported** (§2.11): Cannot substitute with Partial Mesh, so infeasible pairs simply cannot communicate
3. **Development effort vs. benefit**: 12 new Connection modules + Handler extension needed, but above constraints prevent offering "complete" Full-Mesh, limiting return on investment
4. **Practicality of existing aws-to-site**: Star topology (AWS Hub) already has 6 CSP connections complete, and is sufficiently practical for small-scale Multi-Cloud VPN scenarios

#### Conditions for Future Re-evaluation

- Emergence of GCP Classic VPN alternatives or GCP HA VPN Static Routing support
- Migration to AWS Transit Gateway architecture (eliminates VGW 10 Connection limit)
- BGP support expansion via Tencent CCN or IBM Transit Gateway
- Priority change driven by user demand

### 6.3. Designed Execution Order (For Reference)

| Order | Task                                                                              | Duration    | Difficulty | Priority |
| ----- | --------------------------------------------------------------------------------- | ----------- | ---------- | -------- |
| 0-1   | Output structure refactoring (remove cross-references, unique names, standardize) | 1 week      | Low        | Required |
| 0-2   | Develop remaining 12 conn modules                                                 | 1–2 months  | Medium     | Required |
| 1     | **N-CSP Bulk Creation/Deletion API + Phased Destroy + CSP Validation** ★          | 0.5–1 month | Medium     | **Core** |
| 2     | Stabilization + Incremental Connection API (Optional)                             | 1–2 months  | Medium     | Optional |

### 6.4. Key Technical Decisions (Design Record)

1. **Full-Mesh bulk creation/deletion is the Primary API** → Incremental Connection management is Optional
2. **Full-Mesh is guaranteed** → Since Transit Routing is not supported, all pairs are auto-created
3. **Gateway output does not reference connections** → Cross-reference problem resolved
4. **All CSP gateway output names are standardized to `{csp}_vpn_gateway_info`** → Non-standard outputs unified
5. **Connection output uses pair-unique names** → `conn_{pair}_info` format
6. **Full Destroy uses Phased Destroy** → Connection → Gateway order (§2.4)
7. **Handler determines active connections by file existence** → Workspace is the source of truth
8. **CSP constraints are pre-validated at the API level** → AWS VGW 10 Connection limit, etc. (§2.6)
9. **Dynamic/Static Routing hybrid is possible at the Connection level** → However, GCP is BGP-only (§2.12)

### 6.5. Open Discussion Points

1. Finalize development priority for remaining CSP pair modules
2. Timing for AWS Transit Gateway adoption (VGW 10 Connection limit prevents 6+ CSP simultaneous connection)
3. Whether to include DCS in Full-Mesh scope (constraints due to OpenStack VPNaaS characteristics)
4. Securing test environments for each CSP pair during Connection module development
5. Warning/blocking policy for Full-Mesh integrity when incrementally removing Connections
6. Exploring alternatives for GCP ↔ Static CSP connection impossibility (Classic VPN, Transit Gateway, etc.)
7. Value assessment of BGP 4-CSP-only Full-Mesh MVP (AWS, Azure, GCP, Alibaba)

---

## References

### CSP VPN Official Documentation

- **AWS**
  - [AWS Site-to-Site VPN User Guide](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
  - [AWS VPN Gateway Quotas](https://docs.aws.amazon.com/vpn/latest/s2svpn/vpn-limits.html)
  - [AWS BGP Information and Tunnel Options](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPNTunnels.html)
- **Azure**
  - [Azure VPN Gateway Documentation](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)
  - [Azure VPN Gateway FAQ (including APIPA/BGP)](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-vpn-faq)
  - [Azure Active-Active VPN Gateway Configuration](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-activeactive-rm-powershell)
- **GCP**
  - [GCP HA VPN Overview](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview)
  - [GCP Cloud Router BGP Configuration](https://cloud.google.com/network-connectivity/docs/router/concepts/overview)
  - [GCP HA VPN to AWS Connection Guide](https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-aws)
- **Alibaba Cloud**
  - [Alibaba Cloud VPN Gateway Overview](https://www.alibabacloud.com/help/en/vpn-gateway/product-overview/what-is-vpn-gateway)
  - [Alibaba Cloud IPsec-VPN Connection](https://www.alibabacloud.com/help/en/vpn-gateway/user-guide/create-an-ipsec-vpn-connection)
- **Tencent Cloud**
  - [Tencent Cloud VPN Connection Overview](https://www.tencentcloud.com/document/product/1037/32679)
  - [Tencent Cloud Create IPsec VPN Connection](https://www.tencentcloud.com/document/product/1037/32689)
  - [Tencent Cloud VPN Route Configuration](https://www.tencentcloud.com/document/product/1037/39690)
- **IBM Cloud**
  - [IBM Cloud VPN for VPC Overview](https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-overview)
  - [IBM Cloud Create VPN Gateway](https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-create-gateway)
  - [IBM Cloud Add VPN Connections](https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-adding-connections)
- **OpenStack (DCS)**
  - [OpenStack VPNaaS Scenario](https://docs.openstack.org/neutron/latest/admin/vpnaas-scenario.html)
  - [OpenStack Networking API v2 — VPNaaS](https://docs.openstack.org/api-ref/network/v2/)

### Inter-CSP VPN Connection References

- [GCP-AWS HA VPN Configuration Tutorial](https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-aws)
- [GCP-Azure HA VPN Configuration Tutorial](https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-azure)

### OpenTofu / IaC

- [OpenTofu Official Documentation](https://opentofu.org/docs/)
- [OpenTofu CLI — `tofu destroy -target`](https://opentofu.org/docs/cli/commands/destroy/)
- [OpenTofu State Management](https://opentofu.org/docs/language/state/)

### MC-Terrarium Related

- [MC-Terrarium GitHub Repository](https://github.com/cloud-barista/mc-terrarium)
- [cb-tumblebug GitHub Repository](https://github.com/cloud-barista/cb-tumblebug)

---

## Appendix A: Current State Analysis

### A.1. Existing Implementation Status

MC-Terrarium currently has two VPN implementation approaches:

| Implementation   | Path                          | Status             | Description                                                                                      |
| ---------------- | ----------------------------- | ------------------ | ------------------------------------------------------------------------------------------------ |
| **aws-to-site**  | `templates/vpn/aws-to-site/`  | Complete           | Connects from AWS hub to GCP, Azure, Alibaba, Tencent, IBM, DCS                                  |
| **site-to-site** | `templates/vpn/site-to-site/` | Partially complete | Symmetric VPN between CSPs (only conn-aws-azure, conn-azure-gcp, conn-alibaba-azure implemented) |

#### aws-to-site Approach (Star Topology)

```
         ┌──────────┐
    ┌────┤   AWS    ├────┐
    │    │ VPN GW   │    │
    │    └────┬─────┘    │
    │         │          │
    ▼         ▼          ▼
  GCP      Azure     Alibaba    Tencent    IBM    DCS
```

- Uses AWS VPN Gateway as the hub
- Target CSP selected via `target_csp.type` (1:1)
- Independent modules for each target CSP in `modules/{csp}/`
- Only one AWS-to-{single CSP} connection per terrarium

#### site-to-site Approach (Symmetric Pair Topology)

```
  AWS ──── Azure ──── GCP
             │
          Alibaba
```

- Both CSPs create gateways, connected via connection module
- 3-tier structure: `{csp}/` (gateway) → `modules/conn-{csp1}-{csp2}/` (connection logic) → `conn-{csp1}-{csp2}/` (module invocation)
- Currently only 2 CSPs selectable (`len(providers) != 2` validation)
- Available combinations: aws-azure, azure-gcp, alibaba-azure (only 3 combinations implemented)

### A.2. Per-CSP VPN Gateway Characteristics and Constraints

| CSP         | VPN Gateway Type   | BGP Support      | Tunnels                         | Public IPs                | Key Constraints                                                                                |
| ----------- | ------------------ | ---------------- | ------------------------------- | ------------------------- | ---------------------------------------------------------------------------------------------- |
| **AWS**     | VPN Gateway (VGW)  | ✅               | 2 auto-created per Connection   | Assigned per VGW          | 1 VGW per VPC, max 10 VPN Connections per VGW                                                  |
| **Azure**   | Virtual Network GW | ✅               | 1 per Connection                | 2 with Active-Active      | 1 VPN GW per VNet, VpnGw1AZ: max 30 tunnels, APIPA range limited (169.254.21.0–169.254.22.255) |
| **GCP**     | HA VPN Gateway     | ✅               | 2 interfaces per GW × tunnels   | 2 with HA GW              | External GW requires redundancy type, Router interface/peer count limits                       |
| **Alibaba** | VPN Gateway        | ✅               | 2 per Connection (master/slave) | 1 (+ DR IP)               | VPN GW count limit per VPC, dual VSwitch required                                              |
| **Tencent** | VPN Gateway        | ❌ (Static)      | 1 per Connection                | 1 per GW                  | No BGP support (IPSEC type), StaticRoute only, separate APIPA range (169.254.128.0/17)         |
| **IBM**     | VPN Gateway        | ❌ (Route-based) | 1 per Connection                | 2 per GW                  | No BGP support, Policy-based/Route-based selection, Routing table sequential creation required |
| **DCS**     | VPNaaS (OpenStack) | ❌ (Static)      | 1 per Site Connection           | 1 VPN Service external IP | VPNaaS-based, no BGP support, Endpoint Group-based                                             |

#### Key Constraints Summary

1. **AWS VGW: Only 1 per VPC** → A single VPN Gateway must serve multiple CSP connections
2. **Azure VPN GW: Only 1 per VNet** → Multiple connections must be added to a single Gateway
3. **Azure APIPA range limitation** → BGP peering possible only within 169.254.21.0–169.254.22.255 range (approx. 128 /30 subnets max)
4. **GCP HA VPN GW: Fixed 2 interfaces** → Max connections per GW limited
5. **Tencent/IBM/DCS: No BGP support** → Static routing required, manual route management needed
6. **Alibaba: Dual VSwitch required** → 2 availability zones needed

---

## Appendix B: Other Options Review (Options A, B, C)

### B.1. Full-Mesh VPN Challenge Details

#### B.1.1. VPN Gateway Singularity Constraint

**Problem**: 1 VGW per AWS VPC, 1 VPN GW per Azure VNet constraint

Example: Creating AWS-Azure VPN and AWS-GCP VPN in separate terrariums:

- First terrarium: Create AWS VGW-1, Azure VPN GW-1
- Second terrarium: **Conflict** — Cannot create AWS VGW-2 in the same VPC

**→ A structure adding multiple Connections to a single VPN Gateway within one Terrarium is essential**

#### B.1.2. OpenTofu State Management Complexity

Each terrarium currently has an independent OpenTofu state:

- `.terrarium/{trId}/vpn/site-to-site/terraform.tfstate`

When a single terrarium contains all CSPs' VPN gateways and connections:

- State becomes very large
- A single connection change (add/delete) can impact the entire infrastructure
- Apply time increases significantly

#### B.1.3. APIPA Address Management

Azure's APIPA range is limited (169.254.21.0–169.254.22.255):

- /30 subnet units = divided by 4 bytes each
- Total $\frac{512}{4} = 128$ /30 subnets in range
- Per-CSP allocation management needed: 4 for AWS connection, 4 for GCP, 4 for Alibaba, etc.
- Current variables.tf already defines per-CSP APIPA ranges (prevents conflicts)

#### B.1.4. Per-CSP Tunnel/Connection Quota

Number of Connections one CSP Gateway must create in Full-Mesh:

| CSP     | Connections for 6 other CSPs | Tunnels (approx.) | Quota Margin                                        |
| ------- | ---------------------------- | ----------------- | --------------------------------------------------- |
| AWS     | 6 × 2 = 12 connections       | 24 tunnels        | VGW max 10 connections → **exceeded**               |
| Azure   | 6 × 2–4 = 12–24 connections  | 12–24 tunnels     | VpnGw1AZ max 30 → possible, APIPA management needed |
| GCP     | 6 × 2–4 = 12–24 tunnels      | 12–24 tunnels     | Within quota                                        |
| Alibaba | 6 × 2 connections            | 12 tunnels        | Verification needed                                 |
| Tencent | 6 × 2 GW × 2 conn = 24       | 24 connections    | GW count limit verification needed                  |
| IBM     | 6 × 4 connections            | 24 connections    | Verification needed                                 |

**→ AWS VGW's Connection limit (10) may be exceeded when connecting all 6 CSPs simultaneously**

### B.2. Option A: Single Terrarium Full Mesh (Not Recommended)

```
All CSP gateways + all connections in a single terrarium
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
    ├── ... (all 21 combinations)
```

**Pros**: All resources managed in a single state, VPN Gateway sharing is natural

**Cons**: State becomes enormous, single connection change affects entire infrastructure, Apply/Destroy time very long, AWS VGW 10 Connection limit prevents Full Mesh, rollback on partial failure very difficult

### B.3. Option B: Hub-Spoke Based Extension

```
AWS as Hub, each CSP as Spoke (extension of current aws-to-site)
CSP pairs needing additional connections configured as separate terrariums

Terrarium-1: AWS-to-Azure    (aws-to-site)
Terrarium-2: AWS-to-GCP      (aws-to-site)
Terrarium-3: AWS-to-Alibaba  (aws-to-site)
Terrarium-4: Azure-to-GCP    (site-to-site, when using separate Azure/GCP GWs)
```

**Pros**: Can leverage existing aws-to-site implementation, each connection managed independently, easy partial failure recovery

**Cons**: AWS VGW and Azure VPN GW duplicate creation attempted per terrarium → violates 1-per-VPC constraint, requires pattern of creating VPN Gateway externally and importing, transit routing does not work automatically

### B.4. Option C: Gateway/Connection Separation (Issues Discovered During Development)

```
Phase 1: Gateway Provisioning (per CSP, per VPC)
  Terrarium: "gw-aws-vpc1"    → AWS VPN Gateway only
  Terrarium: "gw-azure-vnet1" → Azure VPN Gateway only

Phase 2: Connection Provisioning (per CSP pair)
  Terrarium: "conn-aws-azure" → AWS-Azure VPN Connections only
  Terrarium: "conn-aws-gcp"   → AWS-GCP VPN Connections only
```

**Pros**: Gateway reuse, independent lifecycle, easy quota management, incremental expansion

**Cons**: Architecture change needed, inter-Terrarium state reference mechanism needed, 2-stage user workflow

#### Issues Discovered in Option C

The following three core issues were discovered during actual development:

**Issue 1**: Excessive implementation complexity — Inter-Terrarium state reference mechanism (`terraform_remote_state` or data source), separate lifecycle management logic for Gateway/Connection

**Issue 2**: Complex orchestration for upper subsystems/users — Forces 2-stage workflow, users must manually pass Gateway ID/Public IP, cb-tumblebug bears 2-stage orchestration burden

**Issue 3**: Connection removal difficulty — Output cross-reference problem (gateway output references connection module), output name collision (same CSP's conn info defined redundantly across multiple pairs)

> These issues led to the proposal of **Option D (Single-Terrarium Incremental Composition)**. See [Section 2](#2-option-d-single-terrarium-incremental-composition) of this document.
