##############################################################
## Stage 1 - Go Build
##############################################################

# Using a specific version of golang based on alpine for building the application
FROM golang:1.21.4-alpine AS builder

# Installing necessary packages
# sqlite-libs and sqlite-dev for SQLite support
# build-base for common build requirements
RUN apk add --no-cache sqlite-libs sqlite-dev build-base

# Copying only necessary files for the build
COPY . /go/src/github.com/cloud-barista/mc-terrarium
WORKDIR /go/src/github.com/cloud-barista/mc-terrarium
# COPY go.mod go.sum go.work go.work.sum ./
RUN go mod download
# COPY .tofu ./.tofu
# COPY cmd ./cmd
# COPY conf ./conf
# COPY pkg ./pkg

# Building the Go application with specific flags
# Note - "make prod" executes the command, 
# CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-s -w' -o mc-terrarium"
RUN make prod

#############################################################
## Stage 2 - Application Setup
##############################################################

# Using the latest Ubuntu image for the production stage
FROM ubuntu:latest as prod

# Setting the working directory for the application
WORKDIR /app

# Copying necessary files from the builder stage to the production stage
# Assets, scripts, and configuration files are copied excluding credentials.conf
# which should be specified in .dockerignore
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/.tofu/ /app/.tofu/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/templates/ /app/templates/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/secrets/ /app/secrets/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/conf/ /app/conf/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/scripts/ /app/scripts/
COPY --from=builder /go/src/github.com/cloud-barista/mc-terrarium/cmd/mc-terrarium/mc-terrarium /app/

RUN apt-get update && apt-get install -y git
RUN ./scripts/install-tofu-1.7.1.sh

# Setting various environment variables required by the application
ENV MCTERRARIUM_ROOT=/app \
    LOGFILE_PATH=/app/.tofu/mc-terrarium.log \
    LOGFILE_MAXSIZE=10 \
    LOGFILE_MAXBACKUPS=3 \
    LOGFILE_MAXAGE=30 \
    LOGFILE_COMPRESS=false \
    LOGLEVEL=debug \
    LOGWRITER=both \
    NODE_ENV=development \
    DB_URL=localhost:3306 \
    DB_DATABASE=poc_mc_net_tf \
    DB_USER=poc_mc_net_tf \
    DB_PASSWORD=poc_mc_net_tf \
    API_ALLOW_ORIGINS=* \
    API_AUTH_ENABLED=true \
    API_USERNAME=default \
    API_PASSWORD=default \
    AUTOCONTROL_DURATION_MS=10000 \
    SELF_ENDPOINT=localhost:8888 \
    API_DOC_PATH=/app/pkg/api/rest/docs/swagger.json

# Setting the entrypoint for the application
ENTRYPOINT [ "/app/mc-terrarium" ]

# Exposing the port that the application will run on
EXPOSE 8888
