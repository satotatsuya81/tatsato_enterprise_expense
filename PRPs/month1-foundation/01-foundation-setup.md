name: "01 Foundation Setup - Project Infrastructure"
description: |
  プロジェクトの基盤となるDocker環境、開発ツール、CI/CDパイプライン、
  基本的なプロジェクト構造を構築します。

## Goal
学習用経費精算システムの開発基盤を構築し、Go + Next.js のマイクロサービス環境で
効率的な開発・テスト・デプロイが可能な環境を作成する。

## Why
- 実際のエンタープライズ開発と同様の環境で学習するため
- Docker Composeによる再現可能な開発環境の構築
- CI/CDパイプラインによる品質保証の自動化
- 統一されたコーディング規約とツールチェーンの導入

## What
Docker Compose環境、Makefile、GitHub Actions CI/CD、Linter/Formatter設定、
基本的なプロジェクト構造、README・ドキュメント整備

### Success Criteria
- [ ] Docker Composeで全サービスが起動する
- [ ] Makefileコマンドが正常に動作する
- [ ] GitHub Actions CI/CDが動作する
- [ ] Linter/Formatterがコードを適切にチェックする
- [ ] プロジェクト構造がクリーンアーキテクチャに準拠している

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Include these in your context window
- url: https://docs.docker.com/compose/
  why: Docker Compose設定のベストプラクティス

- url: https://go.dev/doc/code
  why: Go プロジェクト構造の標準的な組織化

- url: https://nextjs.org/docs
  why: Next.js 14 プロジェクト構造

- url: https://threedots.tech/post/ddd-cqrs-clean-architecture-combined/
  why: Go クリーンアーキテクチャ + DDD実装パターン
  critical: ディレクトリ構造、依存性管理の具体例

- url: https://golangci-lint.run/
  why: Go言語の推奨Linter設定
  section: Configuration

- url: https://docs.github.com/en/actions
  why: GitHub Actions CI/CD設定
  section: Workflows syntax
```

### Current Codebase tree
```bash
/Users/tatsuyasato/code/tatosato_keihi/
├── plan/
│   └── plan.md
├── spec/
│   └── enterprise-expense-system.md
├── templates/
│   └── prp_base.md
└── PRPs/
    └── month1-foundation/
        ├── README.md
        ├── 01-foundation-setup.md
        ├── 02-backend-auth-service.md
        ├── 03-frontend-auth-flow.md
        └── 04-integration-testing.md
```

### Desired Codebase tree with files to be added
```bash
/Users/tatsuyasato/code/tatosato_keihi/
├── docker-compose.yml              # 開発環境のサービス定義
├── docker-compose.prod.yml         # 本番環境用の設定
├── Makefile                        # 開発コマンドの統一化
├── .github/
│   └── workflows/
│       ├── backend.yml             # Backend CI/CD
│       ├── frontend.yml            # Frontend CI/CD
│       └── integration.yml         # 統合テスト
├── .gitignore                      # Git除外ファイル設定
├── README.md                       # プロジェクト概要・セットアップ手順
├── services/
│   ├── auth-service/               # 認証マイクロサービス
│   │   ├── cmd/
│   │   │   └── server/
│   │   │       └── main.go
│   │   ├── internal/
│   │   │   ├── domain/
│   │   │   ├── usecase/
│   │   │   ├── adapter/
│   │   │   └── infrastructure/
│   │   ├── go.mod
│   │   ├── go.sum
│   │   ├── Dockerfile
│   │   ├── .golangci.yml
│   │   └── Makefile
│   ├── bff-service/                # BFF マイクロサービス
│   │   └── (同様の構造)
│   ├── expense-service/            # 経費管理サービス (将来)
│   └── workflow-service/           # ワークフローサービス (将来)
├── frontend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.js
│   ├── tailwind.config.js
│   ├── .eslintrc.json
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   ├── lib/
│   │   └── types/
│   └── Dockerfile
├── infrastructure/
│   ├── docker/
│   │   ├── postgres/
│   │   │   └── init.sql
│   │   └── redis/
│   └── nginx/
│       └── nginx.conf
└── scripts/
    ├── setup.sh                   # 初期セットアップスクリプト
    ├── test-integration.sh        # 統合テストスクリプト
    └── build-all.sh              # 全サービスビルドスクリプト
```

### Known Gotchas of our codebase & Library Quirks
```bash
# CRITICAL: Go modules設定
# Go 1.21+ を使用し、各サービスは独立したgo.modを持つ
# ワークスペース機能は使わず、シンプルな構成にする

# CRITICAL: Docker Compose ネットワーク
# サービス間通信はDockerネットワーク名を使用
# ホストマシンからのアクセスはlocalhost:portを使用

# CRITICAL: PostgreSQL設定
# 開発環境では複数スキーマで論理分離
# 本番環境では将来的にサービス毎にDBインスタンス分離

# CRITICAL: Next.js 14 App Router
# Pages Routerではなく、App Routerを使用
# Server ComponentsとClient Componentsの使い分けが重要

# CRITICAL: TypeScript設定
# strict mode有効化、ESLintとPrettierの競合回避

# CRITICAL: CI/CD設定
# GitHub Actionsのjobsを並列実行で高速化
# テスト失敗時の早期終了設定
```

## Implementation Blueprint

### Docker Infrastructure Setup
多段階ビルドとマルチサービス環境の構築

```yaml
# docker-compose.yml の核となる構成
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: expense_system
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./infrastructure/docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  auth-service:
    build:
      context: ./services/auth-service
      dockerfile: Dockerfile
    ports:
      - "8001:8001"
    depends_on:
      - postgres
      - redis
    environment:
      - DATABASE_URL=postgres://postgres:postgres@postgres:5432/expense_system
      - REDIS_URL=redis://redis:6379

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    depends_on:
      - auth-service
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8001
```

### Tasks to be completed in order

```yaml
Task 1: プロジェクト基本構造作成
CREATE project root structure:
  - MKDIR services/ frontend/ infrastructure/ scripts/ .github/workflows/
  - CREATE .gitignore with Go, Node.js, Docker exclusions
  - CREATE README.md with setup instructions and project overview

Task 2: Docker環境構築
CREATE docker-compose.yml:
  - DEFINE postgres service with init script
  - DEFINE redis service for caching/sessions
  - SETUP development network configuration
  - CONFIGURE volume mounts for persistence

CREATE infrastructure/docker/postgres/init.sql:
  - CREATE schemas: auth_schema, expense_schema, workflow_schema, audit_schema
  - CREATE initial admin user
  - SETUP basic permissions

Task 3: Makefileコマンド統一化
CREATE root Makefile:
  - TARGET: up, down, build, test, lint, clean
  - AGGREGATE commands across all services
  - INCLUDE help target with command descriptions

Task 4: GitHub Actions CI/CD
CREATE .github/workflows/backend.yml:
  - TRIGGER on push to services/**
  - JOBS: lint, test, build for all backend services
  - MATRIX strategy for multiple services

CREATE .github/workflows/frontend.yml:
  - TRIGGER on push to frontend/**
  - JOBS: lint, test, build for Next.js

CREATE .github/workflows/integration.yml:
  - TRIGGER on push to main branch
  - JOB: full integration test with Docker Compose

Task 5: Backend service skeleton
CREATE services/auth-service/ basic structure:
  - SETUP go.mod with necessary dependencies
  - CREATE cmd/server/main.go entry point
  - ESTABLISH internal/ directory structure
  - CONFIGURE Dockerfile with multi-stage build
  - SETUP .golangci.yml linter configuration

Task 6: Frontend project initialization
CREATE frontend/ Next.js project:
  - INITIALIZE with create-next-app and TypeScript
  - CONFIGURE tailwind.config.js and next.config.js
  - SETUP src/ directory structure
  - CONFIGURE .eslintrc.json and prettier
  - CREATE Dockerfile for production build

Task 7: Development scripts
CREATE scripts/setup.sh:
  - VERIFY Docker and Docker Compose installation
  - PULL required images
  - RUN initial database setup
  - EXECUTE service health checks

CREATE scripts/test-integration.sh:
  - START all services
  - WAIT for service readiness
  - EXECUTE basic connectivity tests
  - CLEANUP after test completion
```

### Task Details with Pseudocode

#### Task 1: プロジェクト基本構造
```bash
# .gitignore パターン (Go + Node.js + Docker)
# Backend exclusions
*.exe
*.dll
*.so
*.dylib
vendor/
coverage.out

# Frontend exclusions  
node_modules/
.next/
dist/
*.tsbuildinfo

# Infrastructure exclusions
.env
.env.local
docker-compose.override.yml
```

#### Task 2: Docker環境構築
```sql
-- infrastructure/docker/postgres/init.sql
-- CRITICAL: スキーマ分離によるマイクロサービス準備
CREATE SCHEMA IF NOT EXISTS auth_schema;
CREATE SCHEMA IF NOT EXISTS expense_schema;
CREATE SCHEMA IF NOT EXISTS workflow_schema;
CREATE SCHEMA IF NOT EXISTS audit_schema;

-- Initial admin user (development only)
CREATE TABLE auth_schema.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Task 3: Makefile統一化
```makefile
# Root Makefile - 全サービス統合管理
.PHONY: help up down build test lint clean

help: ## Show help message
	@echo "Available commands:"
	@awk '/^[a-zA-Z_-]+:.*?## .*$$/ {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start all services
	docker-compose up -d
	@echo "Services starting... Wait for readiness check"
	./scripts/wait-for-services.sh

down: ## Stop all services  
	docker-compose down

build: ## Build all services
	docker-compose build

test: ## Run all tests
	$(MAKE) -C services/auth-service test
	$(MAKE) -C frontend test

lint: ## Run linting for all services
	$(MAKE) -C services/auth-service lint
	$(MAKE) -C frontend lint

integration-test: ## Run integration tests
	./scripts/test-integration.sh
```

#### Task 5: Backend skeleton
```go
// services/auth-service/cmd/server/main.go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "time"

    "github.com/gin-gonic/gin"
)

func main() {
    // PATTERN: Graceful shutdown with context
    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
    defer stop()

    // PATTERN: Configuration from environment
    port := os.Getenv("PORT")
    if port == "" {
        port = "8001"
    }

    // PATTERN: Router setup with middleware
    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "ok"})
    })

    srv := &http.Server{
        Addr:    ":" + port,
        Handler: r,
    }

    // PATTERN: Graceful shutdown
    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Server failed to start: %v", err)
        }
    }()

    <-ctx.Done()
    log.Println("Shutting down server...")

    shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := srv.Shutdown(shutdownCtx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }
}
```

### Integration Points
```yaml
DOCKER_NETWORK:
  - network: expense_network
  - internal_communication: service_name:port
  - external_access: localhost:port

CONFIG_MANAGEMENT:
  - development: .env files
  - docker: environment variables in compose
  - production: AWS Systems Manager (future)

SERVICE_DISCOVERY:
  - local: Docker Compose internal DNS
  - future: AWS ECS Service Discovery

LOGGING:
  - development: stdout
  - structured: JSON format with correlation IDs
  - aggregation: Docker logs (future: CloudWatch)
```

## Validation Loop

### Level 1: Infrastructure Validation
```bash
# Docker環境確認
docker-compose config --quiet  # 設定ファイル検証
docker-compose up -d           # サービス起動
docker-compose ps              # サービス状態確認

# Expected: All services show "Up" status
# If failing: Check logs with docker-compose logs [service_name]
```

### Level 2: Service Health Checks
```bash
# 各サービスのヘルスチェック
curl -f http://localhost:5432 || echo "Postgres not ready"
curl -f http://localhost:6379 || echo "Redis not ready" 
curl -f http://localhost:8001/health || echo "Auth service not ready"
curl -f http://localhost:3000 || echo "Frontend not ready"

# Expected: All health checks return success
# If failing: Check service logs and port availability
```

### Level 3: Build and Lint Validation
```bash
# Backend validation
make -C services/auth-service lint
make -C services/auth-service test
make -C services/auth-service build

# Frontend validation
make -C frontend lint  
make -C frontend test
make -C frontend build

# Expected: No errors, all builds successful
# If failing: Fix lint errors and failing tests before proceeding
```

### Level 4: CI/CD Pipeline Test
```bash
# GitHub Actions workflow validation (local simulation)
act -W .github/workflows/backend.yml
act -W .github/workflows/frontend.yml

# Or push to GitHub and verify Actions run successfully
git add . && git commit -m "Initial project setup"
git push origin main

# Expected: All CI/CD jobs pass
# If failing: Check GitHub Actions logs, fix configuration
```

## Final validation Checklist
- [ ] Docker Compose起動: `make up` が成功する
- [ ] 全サービスが正常起動: `docker-compose ps` で確認
- [ ] ヘルスチェック通過: 各エンドポイントが応答
- [ ] Linting成功: `make lint` でエラー0件
- [ ] ビルド成功: `make build` で全サービスビルド完了
- [ ] CI/CDパイプライン動作: GitHub Actionsが成功
- [ ] プロジェクト構造確認: 想定ディレクトリ構造が作成されている
- [ ] README.mdが充実: セットアップ手順が明確

---

## Anti-Patterns to Avoid
- ❌ Dockerfileでroot権限を使い続ける
- ❌ .envファイルを本番環境で使用する
- ❌ ヘルスチェックエンドポイントを作らない
- ❌ ログ出力を無視する
- ❌ Make targetに説明を付けない
- ❌ CI/CDで必要な依存関係を省略する

**信頼度レベル: 9/10**
- Docker, Makefile, CI/CDは標準的なパターンで実装済み参考例が豊富
- Go, Next.jsの基本セットアップは確立されたベストプラクティス有り
- 段階的検証により問題の早期発見・修正が可能