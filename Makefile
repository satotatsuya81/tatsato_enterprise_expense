# Enterprise Expense System - Root Makefile
# Unified commands for all services management

.PHONY: help up down build test lint clean logs ps health-check setup dev-up prod-up

# Default target
help: ## Show this help message
	@echo "Enterprise Expense System - Available Commands:"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make setup     # Initial environment setup"
	@echo "  make dev-up    # Start development environment"
	@echo "  make test      # Run all tests"
	@echo "  make lint      # Run all linting"

# Environment Management
setup: ## Initial environment setup and dependency check
	@echo "🚀 Setting up Enterprise Expense System environment..."
	@./scripts/setup.sh

dev-up: ## Start development environment (core services only)
	@echo "🐳 Starting development environment..."
	docker-compose up -d postgres redis
	@echo "⏳ Waiting for core services to be ready..."
	@sleep 10
	@$(MAKE) health-check

up: ## Start all services (full stack)
	@echo "🐳 Starting all services..."
	docker-compose --profile full up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 15
	@$(MAKE) health-check

prod-up: ## Start production environment
	@echo "🚀 Starting production environment..."
	docker-compose -f docker-compose.prod.yml up -d
	@$(MAKE) health-check

down: ## Stop all services
	@echo "🛑 Stopping all services..."
	docker-compose down
	docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

ps: ## Show service status
	@echo "📊 Service Status:"
	@docker-compose ps

logs: ## Show logs for all services
	docker-compose logs -f

logs-auth: ## Show auth service logs
	docker-compose logs -f auth-service

logs-frontend: ## Show frontend logs
	docker-compose logs -f frontend

# Build Commands
build: ## Build all services
	@echo "🔨 Building all services..."
	@$(MAKE) build-auth
	@$(MAKE) build-frontend
	@echo "✅ All services built successfully"

build-auth: ## Build auth service
	@echo "🔨 Building auth service..."
	@if [ -f services/auth-service/Makefile ]; then \
		$(MAKE) -C services/auth-service build; \
	else \
		echo "⚠️ Auth service Makefile not found, skipping..."; \
	fi

build-frontend: ## Build frontend
	@echo "🔨 Building frontend..."
	@if [ -f frontend/package.json ]; then \
		cd frontend && npm run build; \
	else \
		echo "⚠️ Frontend package.json not found, skipping..."; \
	fi

# Testing Commands
test: ## Run all tests
	@echo "🧪 Running all tests..."
	@$(MAKE) test-auth
	@$(MAKE) test-frontend
	@echo "✅ All tests completed"

test-auth: ## Run auth service tests
	@echo "🧪 Running auth service tests..."
	@if [ -f services/auth-service/Makefile ]; then \
		$(MAKE) -C services/auth-service test; \
	else \
		echo "⚠️ Auth service not ready for testing"; \
	fi

test-frontend: ## Run frontend tests
	@echo "🧪 Running frontend tests..."
	@if [ -f frontend/package.json ]; then \
		cd frontend && npm run test; \
	else \
		echo "⚠️ Frontend not ready for testing"; \
	fi

test-integration: ## Run integration tests
	@echo "🔗 Running integration tests..."
	@./scripts/test-integration.sh

# Linting Commands
lint: ## Run linting for all services
	@echo "🔍 Running linting for all services..."
	@$(MAKE) lint-auth
	@$(MAKE) lint-frontend
	@echo "✅ All linting completed"

lint-auth: ## Run auth service linting
	@echo "🔍 Linting auth service..."
	@if [ -f services/auth-service/Makefile ]; then \
		$(MAKE) -C services/auth-service lint; \
	else \
		echo "⚠️ Auth service not ready for linting"; \
	fi

lint-frontend: ## Run frontend linting
	@echo "🔍 Linting frontend..."
	@if [ -f frontend/package.json ]; then \
		cd frontend && npm run lint; \
	else \
		echo "⚠️ Frontend not ready for linting"; \
	fi

# Health Check Commands
health-check: ## Check health of all services
	@echo "🏥 Checking service health..."
	@echo "Postgres:" && (docker-compose exec -T postgres pg_isready -U postgres -d expense_system && echo "✅ Healthy") || echo "❌ Unhealthy"
	@echo "Redis:" && (docker-compose exec -T redis redis-cli ping && echo "✅ Healthy") || echo "❌ Unhealthy"
	@echo "Auth Service:" && (curl -f -s http://localhost:8001/health > /dev/null && echo "✅ Healthy") || echo "❌ Unhealthy"
	@echo "Frontend:" && (curl -f -s http://localhost:3000 > /dev/null && echo "✅ Healthy") || echo "❌ Unhealthy"

wait-for-services: ## Wait for core services to be ready
	@echo "⏳ Waiting for services to be ready..."
	@timeout 60 bash -c 'until docker-compose exec -T postgres pg_isready -U postgres -d expense_system; do sleep 2; done'
	@timeout 60 bash -c 'until docker-compose exec -T redis redis-cli ping; do sleep 2; done'
	@echo "✅ Core services are ready"

# Database Commands
db-shell: ## Connect to database shell
	docker-compose exec postgres psql -U postgres -d expense_system

db-reset: ## Reset database (WARNING: destroys all data)
	@echo "⚠️ This will destroy all database data. Are you sure? [y/N]" && read ans && [ $${ans:-N} = y ]
	docker-compose down
	docker volume rm tatosato_keihi_postgres_data 2>/dev/null || true
	docker-compose up -d postgres
	@$(MAKE) wait-for-services

db-backup: ## Backup database to file
	@echo "💾 Creating database backup..."
	docker-compose exec -T postgres pg_dump -U postgres expense_system > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup created"

# Development Utilities
clean: ## Clean up containers and volumes
	@echo "🧹 Cleaning up containers and volumes..."
	docker-compose down -v
	docker system prune -f
	docker volume prune -f

clean-all: ## Clean everything including images
	@echo "🧹 Cleaning everything..."
	docker-compose down -v --rmi all
	docker system prune -af
	docker volume prune -f

format: ## Format code for all services
	@echo "💅 Formatting code..."
	@$(MAKE) format-auth
	@$(MAKE) format-frontend

format-auth: ## Format auth service code
	@if [ -f services/auth-service/Makefile ]; then \
		$(MAKE) -C services/auth-service format; \
	else \
		echo "⚠️ Auth service not ready for formatting"; \
	fi

format-frontend: ## Format frontend code
	@if [ -f frontend/package.json ]; then \
		cd frontend && npm run format; \
	else \
		echo "⚠️ Frontend not ready for formatting"; \
	fi

# Monitoring
monitor: ## Show real-time service metrics
	@echo "📈 Service Metrics:"
	docker stats

# Documentation
docs-serve: ## Serve documentation locally
	@echo "📚 Starting documentation server..."
	@if command -v python3 > /dev/null; then \
		cd docs && python3 -m http.server 8080; \
	else \
		echo "❌ Python3 not found. Install Python3 to serve docs."; \
	fi

# Security
security-scan: ## Run security scans
	@echo "🔒 Running security scans..."
	@echo "⚠️ Security scanning not implemented yet"

# Environment specific targets
dev: dev-up ## Alias for dev-up

prod: prod-up ## Alias for prod-up

restart: ## Restart all services
	@$(MAKE) down
	@$(MAKE) up

# Git hooks
pre-commit: ## Run pre-commit checks
	@$(MAKE) lint
	@$(MAKE) test

install-hooks: ## Install git hooks
	@echo "🪝 Installing git hooks..."
	@echo '#!/bin/sh\nmake pre-commit' > .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Git hooks installed"