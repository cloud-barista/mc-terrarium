# Makefile for MC-Terrarium in Cloud-Barista.

MODULE_NAME := mc-terrarium
PROJECT_NAME := github.com/cloud-barista/$(MODULE_NAME)
PKG_LIST := $(shell go list $(PROJECT_NAME)/... 2>&1)

GOPROXY_OPTION := GOPROXY=direct # default: GOPROXY=https://proxy.golang.org,direct
GO := $(GOPROXY_OPTION) go
GOPATH := $(shell go env GOPATH)
SWAG := ~/go/bin/swag

.PHONY: all dependency lint update swag swagger build arm prod run stop clean \
	prepare-volumes up down compose compose-down logs \
	init unseal clean-data clean-all \
	help bcrypt

all: swag build ## Default target: build the project

dependency: ## Get dependencies
	@echo "Checking dependencies..."
	@$(GO) mod tidy
	@echo "Checked!"

lint: dependency ## Lint the files
	@echo "Running linter..."
	@if [ ! -f "$(GOPATH)/bin/golangci-lint" ] && [ ! -f "$(shell go env GOROOT)/bin/golangci-lint" ]; then \
		$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.60.2; \
	fi
	@golangci-lint run -E contextcheck -D unused
	@echo "Linter finished!"

update: ## Update all module dependencies
	@echo "Updating dependencies..."
	@cd cmd/$(MODULE_NAME) && $(GO) get -u
	@echo "Checking dependencies..."
	@$(GO) mod tidy
	@echo "Updated!"

swag swagger: ## Generate Swagger API documentation
	@echo "Generating Swagger API documentation..."
	@ln -sf cmd/$(MODULE_NAME)/main.go ./main.go
	@$(SWAG) i --parseDependency --parseInternal --generalInfo ./main.go --dir ./ --output ./api
	@rm ./main.go
	@echo "Generated Swagger API documentation!"

# build: lint swag ## Build the binary file for amd64
build: ## Build the binary file for amd64
	@echo "Building the binary for amd64..."
	@cd cmd/$(MODULE_NAME) && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO) build -o $(MODULE_NAME) main.go
	@echo "Build finished!"

# arm: lint swag ## Build the binary file for ARM
arm: ## Build the binary file for ARM
	@echo "Building the binary for ARM..."
	@cd cmd/$(MODULE_NAME) && CGO_ENABLED=0 GOOS=linux GOARCH=arm $(GO) build -o $(MODULE_NAME)-arm main.go
	@echo "Build finished!"

# prod: lint swag ## Build the binary file for production
prod: ## Build the binary file for production
	@echo "Building the binary for amd64 production..."
# Note - Using cgo write normal Go code that imports a pseudo-package "C". I may not need on cross-compiling.
# Note - You can find possible platforms by 'go tool dist list' for GOOS and GOARCH
# Note - Using the -ldflags parameter can help set variable values at compile time.
# Note - Using the -s and -w linker flags can strip the debugging information.		
	@cd cmd/$(MODULE_NAME) && \
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO) build \
		-ldflags '-s -w' \
		-tags $(MODULE_NAME) \
		-v -o $(MODULE_NAME) \
		main.go
	@echo "Build finished!"

run: build ## Run the built binary
	@echo "Running the binary..."
	@source conf/setup.env; \
	cd cmd/$(MODULE_NAME) && \
	(./$(MODULE_NAME) || { echo "Trying with sudo..."; sudo ./$(MODULE_NAME); })

stop: ## Stop the built binary
	@echo "Stopping the binary..."
	@sudo killall $(MODULE_NAME) 2>/dev/null || true
	@echo "Stopped!"

clean: ## Remove previous build
	@echo "Cleaning build..."
	@rm -f coverage.out
	@rm -f api/docs.go api/swagger.*
	@cd cmd/$(MODULE_NAME) && $(GO) clean
	@echo "Cleaned!"

prepare-volumes: ## Create bind-mount directories with current user ownership
	@echo "Preparing container-volume directories..."
	@mkdir -p container-volume/mc-terrarium-container/.terrarium
	@mkdir -p container-volume/openbao-data
	@echo "Prepared!"
# Note: mc-terrarium runs as appuser (UID 1000) inside the container.
# Docker auto-creates missing bind-mount dirs as root, making them unwritable.
# Pre-creating here ensures ownership matches the host user (typically UID 1000).
# OpenBao data dir ownership is fixed by entrypoint chown in docker-compose.yaml.

# ── Docker Compose targets ──────────────────────────────────────────
# docker-compose.yaml includes both mc-terrarium and OpenBao services.
#
# Usage scenarios:
#   1) Fresh start:       make compose → make init
#   2) Reset app data:    make clean-data → make compose
#   3) Full reset:        make clean-all  → make compose → make init

init: ## Register CSP credentials into OpenBao (run manually after compose)
	@echo "Initializing OpenBao and registering credentials..."
	@bash init/init.sh

up: compose ## Build and start all services (auto init/unseal OpenBao)

down: compose-down ## Stop and remove all services

unseal: ## Unseal OpenBao (needed after every restart)
	@echo "Trying to unseal OpenBao (if not already unsealed)..."
	@bash init/unseal-openbao.sh || true

compose: swag prepare-volumes ## Build and start all services (auto init/unseal OpenBao)
	@echo "Building images..."
	@DOCKER_BUILDKIT=1 docker compose build
	@echo "Starting OpenBao..."
	@docker compose up -d openbao
	@if [ ! -f .env ] || ! grep -q '^VAULT_TOKEN=.\+' .env 2>/dev/null; then \
		echo "VAULT_TOKEN not found — running first-time OpenBao initialization..."; \
		bash init/init-openbao.sh; \
	fi
	@$(MAKE) unseal
	@echo "Starting all services..."
	@docker compose up -d
	@echo ""
	@echo "To register CSP credentials, run:  make init"
	@$(MAKE) logs

compose-down: ## Stop and remove all services
	@echo "Stopping all services..."
	@docker compose down

clean-data: compose-down ## Reset terrarium data (keep OpenBao)
	@echo "Cleaning terrarium data (keeping OpenBao data)..."
	@rm -rf container-volume/mc-terrarium-container
	@echo "Cleaned! Run 'make compose' to restart."

clean-all: compose-down ## Full reset including OpenBao (requires re-init)
	@echo "Cleaning all data including OpenBao..."
	sudo rm -rf container-volume
	@rm -f secrets/openbao-init.json
	@sed -i 's/^VAULT_TOKEN=.*/VAULT_TOKEN=/' .env 2>/dev/null || true
	@echo "Cleaned! Run 'make compose' to rebuild and re-initialize."

logs: ## Follow logs of all services (Ctrl+C to stop)
	@docker compose logs -f

bcrypt: ## Generate bcrypt hash for given password (usage: make bcrypt PASSWORD=mypassword)
	@if [ -z "$(PASSWORD)" ]; then \
		echo "Please provide a password: make bcrypt PASSWORD=mypassword"; \
		exit 1; \
	fi
	@mkdir -p cmd/bcrypt
	@if [ ! -f "cmd/bcrypt/bcrypt" ]; then \
		echo "bcrypt binary not found, building it..."; \
		go build -o cmd/bcrypt/bcrypt cmd/bcrypt/main.go; \
		chmod +x cmd/bcrypt/bcrypt; \
	fi
	@echo "$(PASSWORD)" | ./cmd/bcrypt/bcrypt

help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
