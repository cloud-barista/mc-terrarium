# syntax=docker/dockerfile:1.4

##############################################################
## Stage 1 - Go Build
##############################################################

# Using a specific version of golang based on alpine for building the application
FROM golang:1.25.0-alpine AS builder

# Installing necessary packages
# build-base for common build requirements
RUN apk add --no-cache build-base

WORKDIR /go/src/github.com/cloud-barista/mc-terrarium

# Cache dependencies - copy go.mod/go.sum first for better layer caching
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

# Copying necessary source files for the build
COPY cmd ./cmd
COPY pkg ./pkg
COPY api ./api
COPY conf ./conf
COPY templates ./templates
COPY scripts ./scripts
COPY .terrarium ./.terrarium

# Building the Go application with cache mounts
# Note - "make prod" executes: CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-s -w' -o mc-terrarium main.go
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    cd cmd/mc-terrarium && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-s -w' -o mc-terrarium main.go

# [Legacy] Building with Makefile (without cache optimization)
# COPY . .
# RUN make prod

# [Legacy] Installing OpenTofu via script in builder stage
# RUN ./scripts/install-tofu.sh


##############################################################
## Stage 2 - OpenTofu Binary
##############################################################

# Using minimal OpenTofu image for multi-stage build
# See https://opentofu.org/docs/intro/install/docker/
FROM ghcr.io/opentofu/opentofu:1.11.4-minimal AS tofu


#############################################################
## Stage 3 - Application Setup
#############################################################

# Using Alpine for a lightweight production image
FROM alpine:3.21 AS prod

# [Legacy] Using Ubuntu image for the production stage
# FROM ubuntu:22.04 AS prod

# Installing ca-certificates for HTTPS connections
RUN apk add --no-cache ca-certificates curl

# Copying the tofu binary from the minimal OpenTofu image
COPY --from=tofu /usr/local/bin/tofu /usr/local/bin/tofu

# [Legacy] Copying the tofu binary from the builder stage (when using install-tofu.sh)
# COPY --from=builder /usr/bin/tofu /usr/bin/tofu

# Setting the working directory for the application
WORKDIR /app

# Create non-root user for secure execution
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D -h /app appuser

# Create writable directories owned by appuser
RUN mkdir -p /app/log && chown appuser:appgroup /app/log

# Copying necessary files from the builder stage to the production stage
# Assets, scripts, and configuration files are copied excluding credentials.conf
# which should be specified in .dockerignore
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/.terrarium/ /app/.terrarium/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/templates/ /app/templates/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/conf/ /app/conf/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/scripts/ /app/scripts/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/cmd/mc-terrarium/mc-terrarium /app/
# COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/secrets/ /app/secrets/

# Setting various environment variables required by the application
ENV TERRARIUM_ROOT=/app

## Set SELF_ENDPOINT, to access Swagger API dashboard outside (Ex: export SELF_ENDPOINT=x.x.x.x:8055)
ENV TERRARIUM_SELF_ENDPOINT=localhost:8055

## Set API access config
# API_ALLOW_ORIGINS (ex: https://cloud-barista.org,xxx.xxx.xxx.xxx or * for all)
# Set ENABLE_AUTH=true currently for basic auth for all routes (i.e., url or path)
ENV TERRARIUM_API_ALLOW_ORIGINS=* \
    TERRARIUM_API_AUTH_ENABLED=true \
    TERRARIUM_API_USERNAME=default \
    TERRARIUM_API_PASSWORD='$2a$10$cKUlDfR8k4VUubhhRwCV9.sFvKV3KEc9RJ.H8R/thIeVOrhQ.nuuW'

## Logger configuration
# Set log file path (relative to TERRARIUM_ROOT, joined as /app/log/terrarium.log)
# Set log level, such as trace, debug info, warn, error, fatal, and panic
ENV TERRARIUM_LOGFILE_PATH=log/terrarium.log \
    TERRARIUM_LOGFILE_MAXSIZE=1000 \
    TERRARIUM_LOGFILE_MAXBACKUPS=3 \
    TERRARIUM_LOGFILE_MAXAGE=30 \
    TERRARIUM_LOGFILE_COMPRESS=false \
    TERRARIUM_LOGLEVEL=info \
    TERRARIUM_LOGWRITER=both

# Set execution environment, such as development or production
ENV TERRARIUM_NODE_ENV=production

## Set period for auto control goroutine invocation
ENV TERRARIUM_AUTOCONTROL_DURATION_MS=10000

## OpenBao (secrets management) configuration
## Set by docker-compose.yaml at runtime.
## OpenTofu vault provider auto-reads VAULT_ADDR and VAULT_TOKEN.
ENV VAULT_ADDR=http://localhost:8200 \
    VAULT_TOKEN=

# Run as non-root user (UID 1000)
# See: https://docs.docker.com/build/building/best-practices/#user
USER appuser

# Setting the entrypoint for the application
ENTRYPOINT [ "/app/mc-terrarium" ]

# Exposing the port that the application will run on
EXPOSE 8055
