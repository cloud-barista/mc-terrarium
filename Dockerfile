##############################################################
## Stage 1 - Go Build
##############################################################

# Using a specific version of golang based on alpine for building the application
FROM golang:1.25.0-alpine AS builder

# Installing necessary packages
# sqlite-libs and sqlite-dev for SQLite support
# build-base for common build requirements
RUN apk add --no-cache sqlite-libs sqlite-dev build-base curl

# Copying only necessary files for the build
COPY . /go/src/github.com/cloud-barista/mc-terrarium
WORKDIR /go/src/github.com/cloud-barista/mc-terrarium
# COPY go.mod go.sum go.work go.work.sum ./
RUN go mod download
# COPY .terrarium ./.terrarium
# COPY cmd ./cmd
# COPY conf ./conf
# COPY pkg ./pkg

# Building the Go application with specific flags
# Note - "make prod" executes the command, 
# CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-s -w' -tags mc-terrarium -v -o mc-terrarium main.go
RUN make prod

# Installing OpenTofu
RUN ./scripts/install-tofu.sh


#############################################################
## Stage 2 - Application Setup
##############################################################

# Using the latest Ubuntu image for the production stage
FROM ubuntu:22.04 AS prod

# Coying the tofu binary from the builder stage
COPY --from=builder /usr/bin/tofu /usr/bin/tofu

# Setting the working directory for the application
WORKDIR /app

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
# Set log file path (default logfile path: ./log/terrarium.log)
# Set log level, such as trace, debug info, warn, error, fatal, and panic
ENV TERRARIUM_LOGFILE_PATH=/app/log/terrarium.log \
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

# Setting the entrypoint for the application
ENTRYPOINT [ "/app/mc-terrarium" ]

# Exposing the port that the application will run on
EXPOSE 8055
