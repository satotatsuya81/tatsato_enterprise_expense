# Auth Service Makefile

.PHONY: help build run test lint clean dev docker-build docker-run deps

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOLINT=golangci-lint

# Binary info
BINARY_NAME=auth-service
MAIN_PATH=./cmd/server
BINARY_UNIX=$(BINARY_NAME)_unix

# Docker info
DOCKER_IMAGE=auth-service
DOCKER_TAG=latest

help: ## Show this help message
	@echo "Auth Service - Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development commands
deps: ## Download Go modules
	$(GOMOD) download
	$(GOMOD) verify

tidy: ## Tidy Go modules
	$(GOMOD) tidy

dev: ## Run in development mode with hot reload
	air -c .air.toml

run: ## Run the application
	$(GOBUILD) -o $(BINARY_NAME) -v $(MAIN_PATH)
	./$(BINARY_NAME)

# Build commands
build: ## Build the binary
	$(GOBUILD) -o $(BINARY_NAME) -v $(MAIN_PATH)

build-linux: ## Build for Linux
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(BINARY_UNIX) -v $(MAIN_PATH)

build-prod: ## Build for production
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) \
		-ldflags='-w -s -extldflags "-static"' \
		-a -installsuffix cgo \
		-o $(BINARY_NAME) $(MAIN_PATH)

# Test commands
test: ## Run tests
	$(GOTEST) -v ./...

test-coverage: ## Run tests with coverage
	$(GOTEST) -v -coverprofile=coverage.out ./...
	$(GOCMD) tool cover -html=coverage.out -o coverage.html

test-race: ## Run tests with race detector
	$(GOTEST) -v -race ./...

test-short: ## Run short tests
	$(GOTEST) -v -short ./...

bench: ## Run benchmarks
	$(GOTEST) -v -bench=. -benchmem ./...

# Code quality commands
lint: ## Run linter
	$(GOLINT) run

lint-fix: ## Run linter with auto-fix
	$(GOLINT) run --fix

format: ## Format code
	$(GOCMD) fmt ./...
	goimports -w .

vet: ## Run go vet
	$(GOCMD) vet ./...

# Security commands
security: ## Run security checks
	gosec ./...

# Docker commands
docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker-build-dev: ## Build Docker image for development
	docker build --target development -t $(DOCKER_IMAGE):dev .

docker-run: ## Run Docker container
	docker run --rm -p 8001:8001 \
		-e DATABASE_URL=postgres://postgres:postgres@host.docker.internal:5432/expense_system \
		-e REDIS_URL=redis://host.docker.internal:6379 \
		-e JWT_SECRET=development_secret \
		$(DOCKER_IMAGE):$(DOCKER_TAG)

docker-run-dev: ## Run Docker container in development mode
	docker run --rm -p 8001:8001 \
		-v $(PWD):/app \
		-e DATABASE_URL=postgres://postgres:postgres@host.docker.internal:5432/expense_system \
		-e REDIS_URL=redis://host.docker.internal:6379 \
		-e JWT_SECRET=development_secret \
		$(DOCKER_IMAGE):dev

# Database commands
db-migrate: ## Run database migrations (placeholder)
	@echo "Database migrations not implemented yet"

db-seed: ## Seed database with test data (placeholder)
	@echo "Database seeding not implemented yet"

# Utility commands
clean: ## Clean build artifacts
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
	rm -f $(BINARY_UNIX)
	rm -f coverage.out
	rm -f coverage.html

install-tools: ## Install development tools
	$(GOGET) -u github.com/cosmtrek/air
	$(GOGET) -u github.com/golangci/golangci-lint/cmd/golangci-lint
	$(GOGET) -u golang.org/x/tools/cmd/goimports
	$(GOGET) -u github.com/securecodewarrior/sast-scan/cmd/gosec

check: ## Run all checks
	$(MAKE) lint
	$(MAKE) vet
	$(MAKE) test
	$(MAKE) security

# CI/CD commands
ci: ## Run CI pipeline locally
	$(MAKE) deps
	$(MAKE) lint
	$(MAKE) test-race
	$(MAKE) build

# Environment setup
setup-dev: ## Setup development environment
	$(MAKE) install-tools
	$(MAKE) deps
	@echo "Development environment setup complete"

# Health check
health: ## Check if service is running
	@curl -f http://localhost:8001/health || echo "Service not running"

# Show current status
status: ## Show project status
	@echo "=== Auth Service Status ==="
	@echo "Go version: $(shell go version)"
	@echo "Module: $(shell head -1 go.mod)"
	@echo "Binary exists: $(shell test -f $(BINARY_NAME) && echo "Yes" || echo "No")"
	@echo "Docker image: $(shell docker images -q $(DOCKER_IMAGE):$(DOCKER_TAG) | head -1 || echo "Not built")"