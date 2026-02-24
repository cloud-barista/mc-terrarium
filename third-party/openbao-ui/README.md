# OpenBao with Web UI

The official [OpenBao Docker image](https://hub.docker.com/r/openbao/openbao) (`openbao/openbao`) does **not** include the Web UI.
This directory provides a Dockerfile that builds OpenBao from source with the Ember.js-based Web UI included.

> **Note**: This is an optional component for contributors who want to explore
> OpenBao via a browser-based UI.
> MC-Terrarium works perfectly without it — the default `openbao/openbao` image
> with API/CLI access is sufficient for all operations.

> **See also**: The OpenBao community is actively working on UI modernization
> ([Issue #1364](https://github.com/openbao/openbao/issues/1364)).
> For details on why the UI was excluded from earlier official images, see
> [Appendix: Why Was the UI Missing from Official Docker Images?](#appendix-why-was-the-ui-missing-from-official-docker-images)
> at the bottom of this document.

## Prerequisites

- Docker (with BuildKit support)
- ~4 GB of free disk space for intermediate build layers
- 10–30 minutes for the initial build (downloads OpenBao source, builds
  Ember.js UI and Go binary)

## Build

From the **mc-terrarium project root**:

```bash
docker build -f third-party/openbao-ui/Dockerfile -t openbao:dev-ui .
```

### Build Arguments

| Argument          | Default  | Description                  |
| ----------------- | -------- | ---------------------------- |
| `OPENBAO_VERSION` | `v2.5.1` | Git tag to build from        |
| `GO_VERSION`      | `1.25.7` | Go toolchain version         |
| `NODE_VERSION`    | `22`     | Node.js version for UI build |

To build a different version:

```bash
docker build -f third-party/openbao-ui/Dockerfile \
  --build-arg OPENBAO_VERSION=v2.5.1 \
  -t openbao:dev-ui .
```

## Usage

### Standalone (quick test)

```bash
docker run -d --name openbao-ui \
  --cap-add IPC_LOCK \
  -p 8200:8200 \
  -e BAO_ADDR=http://0.0.0.0:8200 \
  -e BAO_DEV_ROOT_TOKEN_ID=root-token \
  openbao:dev-ui server -dev
```

Open http://localhost:8200/ui/ and sign in with token `root-token`.

### With Docker Compose

Set `OPENBAO_IMAGE` in your `.env` file (or export it):

```bash
# .env
BAO_TOKEN=root-token
OPENBAO_IMAGE=openbao:dev-ui
```

Then start as usual:

```bash
docker compose up -d
```

The `docker-compose.yaml` uses `${OPENBAO_IMAGE:-openbao/openbao:2.5.1}`,
so it will pick up the UI-enabled image automatically.

## Cleanup

```bash
# Remove test container
docker rm -f openbao-ui

# Remove built image (optional)
docker rmi openbao:dev-ui
```

## How It Works

The Dockerfile uses a 3-stage multi-stage build:

1. **ui-builder** (Node.js) — Clones OpenBao source, installs dependencies via
   Yarn, builds the Ember.js app
2. **go-builder** (Go) — Compiles the OpenBao server binary with the `ui` build
   tag, embedding the UI assets
3. **runtime** (Alpine) — Minimal image with only the compiled `bao` binary and
   runtime dependencies

## Reference

- [OpenBao GitHub](https://github.com/openbao/openbao)
- [OpenBao Documentation](https://openbao.org/docs/)
- [OpenBao UI source & contribution guide](https://github.com/openbao/openbao/tree/main/ui)
- [Issue #739 — Tracking: Reintroduction of UI to Release Builds](https://github.com/openbao/openbao/issues/739)
- [Issue #1364 — UI Modernization](https://github.com/openbao/openbao/issues/1364)

---

## Appendix: Why Was the UI Missing from Official Docker Images?

[OpenBao](https://github.com/openbao/openbao) is a community-driven fork of
HashiCorp Vault, started after Vault switched from an open-source license to the
Business Source License (BSL) in August 2023. During the fork, OpenBao inherited
the entire Vault codebase — including the Ember.js-based Web UI under the `ui/`
directory.

However, the inherited UI could not be shipped as-is for the following reasons:

| Issue | Details |
| ----- | ------- |
| **HashiCorp branding** | The UI contained Vault logos, product names, and links to `vaultproject.io` documentation. These had to be replaced before OpenBao could distribute its own builds. ([#74](https://github.com/openbao/openbao/issues/74), [#643](https://github.com/openbao/openbao/pull/643), [#668](https://github.com/openbao/openbao/pull/668), [#669](https://github.com/openbao/openbao/pull/669)) |
| **Enterprise feature references** | UI pages referenced Vault Enterprise–only features (Sentinel policies, HCP Link status, DR/PR replication, client counts) that do not exist in OpenBao. ([#129](https://github.com/openbao/openbao/issues/129), [#684](https://github.com/openbao/openbao/pull/684), [#734](https://github.com/openbao/openbao/pull/734), [#735](https://github.com/openbao/openbao/pull/735)) |
| **Failing tests** | The inherited test suite had many failures on the OpenBao codebase. ([#154](https://github.com/openbao/openbao/issues/154), [#784](https://github.com/openbao/openbao/pull/784)) |
| **Build toolchain issues** | The Ember.js build did not work reliably across all platforms and Node.js versions. ([#417](https://github.com/openbao/openbao/issues/417), [#731](https://github.com/openbao/openbao/issues/731)) |
| **Vulnerable dependencies** | The UI's npm dependencies had known security vulnerabilities that needed to be resolved. ([#752](https://github.com/openbao/openbao/issues/752), [#807](https://github.com/openbao/openbao/pull/807)) |

As a result, **every official release from v2.0.0-alpha20240329 through v2.1.0
(November 2024)** shipped with the explicit warning:

> *"WARNING: OpenBao's Release does not include the builtin WebUI!"*

The OpenBao team tracked the reintroduction effort in
[**Issue #739 — Tracking: Reintroduction of UI to Release Builds**](https://github.com/openbao/openbao/issues/739).
After extensive cleanup, [**PR #940 — Add UI to release workflow**](https://github.com/openbao/openbao/pull/940)
was merged on January 27, 2025, and **v2.2.0 (March 5, 2025) became the first
official release with Web UI support**.

### Current Status

| Version | UI in Release Binaries | UI in Docker Image |
| ------- | ---------------------- | ------------------ |
| v2.0.0-alpha ~ v2.1.0 | No | No |
| v2.2.0+ | **Yes** | Depends on image build pipeline |

Starting with v2.2.0, the GitHub Releases page provides binaries compiled with
the `ui` build tag. However, depending on how the Docker image is built and
published, the `openbao/openbao` image on Docker Hub **may still not include the
UI**. If running `bao server -dev` shows:

```
OpenBao UI is not available in this binary.
```

It means the binary was compiled without the `ui` build tag. In that case, use
the Dockerfile provided in this directory to build an image with UI included.
