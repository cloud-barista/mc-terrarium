# OpenBao with UI - Multi-stage build
#
# This Dockerfile builds OpenBao from source with the Web UI included.
# The official openbao/openbao Docker image does NOT include the UI.
#
# Build (from the mc-terrarium project root):
#   docker build -f third-party/openbao-ui/Dockerfile -t openbao:dev-ui .
#
# Note: This build downloads the OpenBao source and compiles both the
#       Ember.js UI and Go server. It may take 10-30 minutes depending
#       on your machine.

ARG OPENBAO_VERSION=v2.5.1
ARG GO_VERSION=1.25.7
ARG NODE_VERSION=22

##############################################################
## Stage 1 - Build UI assets (Ember.js)
##############################################################
FROM node:${NODE_VERSION}-bookworm AS ui-builder

ARG OPENBAO_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 --branch ${OPENBAO_VERSION} \
    https://github.com/openbao/openbao.git .

WORKDIR /build/ui
RUN corepack enable && \
    yarn install --frozen-lockfile && \
    npm rebuild node-sass 2>/dev/null || true && \
    yarn run build

##############################################################
## Stage 2 - Build OpenBao binary with UI
##############################################################
FROM golang:${GO_VERSION}-bookworm AS go-builder

ARG OPENBAO_VERSION

WORKDIR /go/src/github.com/openbao/openbao

# Copy source from ui-builder (includes built UI assets)
COPY --from=ui-builder /build /go/src/github.com/openbao/openbao

# Build with UI tag
RUN CGO_ENABLED=0 BUILD_TAGS="ui" OPENBAO_DEV_BUILD=1 \
    GOOS=linux GOARCH=$(go env GOARCH) \
    sh -c './scripts/build.sh'

##############################################################
## Stage 3 - Runtime image
##############################################################
FROM alpine:3.21

# Create openbao user and group
RUN addgroup openbao && \
    adduser -S -G openbao openbao

# Install runtime dependencies
RUN set -eux; \
    apk add --no-cache ca-certificates libcap su-exec dumb-init tzdata curl

# Copy binary from builder
COPY --from=go-builder /go/src/github.com/openbao/openbao/bin/bao /bin/bao

# Setup directories
RUN mkdir -p /openbao/logs && \
    mkdir -p /openbao/file && \
    mkdir -p /openbao/config && \
    mkdir -p /bao/data && \
    chown -R openbao:openbao /openbao /bao

VOLUME /openbao/logs
VOLUME /openbao/file
VOLUME /bao/data

EXPOSE 8200

# Use same entrypoint pattern as official image
COPY --from=go-builder /go/src/github.com/openbao/openbao/scripts/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server", "-dev"]
