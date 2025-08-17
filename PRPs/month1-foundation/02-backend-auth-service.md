name: "02 Backend Auth Service - Clean Architecture & JWT Authentication"
description: |
  クリーンアーキテクチャとDDDパターンを実践し、JWT認証システムと
  ユーザー管理APIを実装します。

## Goal
クリーンアーキテクチャの4層構造を実装し、JWT認証・ユーザー管理機能を持つ
スケーラブルで保守性の高い認証マイクロサービスを構築する。

## Why
- クリーンアーキテクチャの実践による保守性向上
- DDDパターンによるビジネスロジックの明確化
- JWT認証によるステートレスなマイクロサービス設計
- テスト容易性とコードの再利用性向上

## What
JWT認証API、ユーザーCRUD API、ミドルウェア、リポジトリパターン、
DDD実装（エンティティ、値オブジェクト、ドメインサービス）、
PostgreSQL統合、Redis Session管理

### Success Criteria
- [ ] クリーンアーキテクチャの4層が正しく実装されている
- [ ] JWT認証が完全に動作する（生成・検証・リフレッシュ）
- [ ] ユーザー管理API（CRUD）が動作する
- [ ] パスワードハッシュ化・検証が適切に実装されている
- [ ] PostgreSQL、Redisとの統合が完了している
- [ ] 単体テストカバレッジが80%以上
- [ ] API仕様が明確に文書化されている

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Include these in your context window
- url: https://threedots.tech/post/ddd-cqrs-clean-architecture-combined/
  why: Go DDD + クリーンアーキテクチャ実装パターン
  critical: レイヤー構造、依存性逆転の具体例

- url: https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example
  why: 実際のGo DDD実装例
  section: user management, authentication patterns

- url: https://pkg.go.dev/github.com/golang-jwt/jwt/v5
  why: JWT library v5の最新API
  section: Claims, signing methods

- url: https://gin-gonic.com/docs/
  why: Gin framework patterns
  section: Middleware, routing, binding

- url: https://golang.org/pkg/golang.org/x/crypto/bcrypt/
  why: パスワードハッシュ化ベストプラクティス

- url: https://gorm.io/docs/
  why: GORM v2 patterns
  section: hooks, associations, transactions

- url: https://github.com/go-redis/redis
  why: Redis client patterns
  section: connection pooling, TTL management
```

### Current Codebase tree (after 01-foundation-setup completion)
```bash
/Users/tatsuyasato/code/tatosato_keihi/
├── services/
│   └── auth-service/
│       ├── cmd/
│       │   └── server/
│       │       └── main.go
│       ├── internal/
│       ├── go.mod
│       ├── go.sum
│       ├── Dockerfile
│       ├── .golangci.yml
│       └── Makefile
├── infrastructure/
│   └── docker/
│       └── postgres/
│           └── init.sql
└── docker-compose.yml
```

### Desired Codebase tree with files to be added
```bash
services/auth-service/
├── cmd/
│   └── server/
│       └── main.go                 # アプリケーションエントリーポイント
├── internal/
│   ├── domain/                     # Domain Layer (最内層)
│   │   ├── entity/
│   │   │   └── user.go            # User entity with business rules
│   │   ├── value_object/
│   │   │   ├── email.go           # Email value object
│   │   │   ├── password.go        # Password value object
│   │   │   └── user_id.go         # UserID value object
│   │   ├── repository/
│   │   │   └── user_repository.go # Repository interface
│   │   └── service/
│   │       └── auth_service.go    # Domain service for auth logic
│   ├── usecase/                   # Application Layer
│   │   ├── interactor/
│   │   │   ├── auth_interactor.go # Authentication use cases
│   │   │   └── user_interactor.go # User management use cases
│   │   ├── port/
│   │   │   ├── input/
│   │   │   │   ├── auth_input.go  # Input port interfaces
│   │   │   │   └── user_input.go
│   │   │   └── output/
│   │   │       ├── auth_output.go # Output port interfaces
│   │   │       └── user_output.go
│   │   └── dto/
│   │       ├── auth_dto.go        # Data transfer objects
│   │       └── user_dto.go
│   ├── adapter/                   # Interface Adapters Layer
│   │   ├── controller/
│   │   │   ├── auth_controller.go # HTTP handlers
│   │   │   └── user_controller.go
│   │   ├── presenter/
│   │   │   ├── auth_presenter.go  # Response formatting
│   │   │   └── user_presenter.go
│   │   ├── gateway/
│   │   │   ├── jwt_gateway.go     # JWT handling
│   │   │   └── redis_gateway.go   # Redis operations
│   │   └── repository/
│   │       └── user_repository.go # Repository implementation
│   └── infrastructure/            # Infrastructure Layer (最外層)
│       ├── database/
│       │   ├── connection.go      # DB connection management
│       │   └── migration.go       # Database migrations
│       ├── server/
│       │   ├── router.go          # HTTP routing setup
│       │   ├── middleware.go      # Authentication middleware
│       │   └── handler.go         # Handler registration
│       └── config/
│           ├── config.go          # Configuration management
│           └── env.go             # Environment variables
├── pkg/                           # Public packages
│   ├── errors/
│   │   └── errors.go              # Custom error types
│   └── utils/
│       ├── validator.go           # Input validation utilities
│       └── logger.go              # Logging utilities
├── tests/
│   ├── unit/
│   │   ├── domain/
│   │   ├── usecase/
│   │   └── adapter/
│   └── integration/
│       └── api_test.go            # API integration tests
├── docs/
│   └── api.md                     # API documentation
├── go.mod
├── go.sum
├── Dockerfile
├── .golangci.yml
└── Makefile
```

### Known Gotchas of our codebase & Library Quirks
```go
// CRITICAL: JWT v5 API変更点
// 古いバージョンとは異なるClaims処理が必要
jwt.RegisteredClaims{} // v5での標準クレーム

// CRITICAL: GORM v2のHooks
// BeforeCreate, BeforeUpdate hooks for timestamps
// Association handling has changed

// CRITICAL: Gin Context binding
// ShouldBindJSON vs BindJSON の使い分け
// バリデーション失敗時の適切なエラーレスポンス

// CRITICAL: bcrypt cost設定
// 開発環境では低コスト、本番環境では適切なコスト設定
const BcryptCost = 12 // for production

// CRITICAL: Redis TTL設定
// JWTのexpiration timeとRedis TTLの整合性が重要
// リフレッシュトークンの適切な管理

// CRITICAL: PostgreSQL transaction管理
// GORM transaction scopeの適切な使用
// 複数テーブル操作時の一貫性保証

// CRITICAL: 依存性注入パターン
// interface実装をコンストラクタで注入
// テスト時のモック化を考慮した設計
```

## Implementation Blueprint

### Domain Layer Design (DDD Core)
ビジネスルールとエンティティの実装

```go
// User entity with business invariants
type User struct {
    id       UserID
    email    Email
    password Password
    role     Role
    profile  Profile
    createdAt time.Time
    updatedAt time.Time
}

// CRITICAL: Business rules enforcement
func (u *User) ChangePassword(oldPassword, newPassword string) error {
    if !u.password.Verify(oldPassword) {
        return ErrInvalidPassword
    }
    // Password policy validation in domain
    newPass, err := NewPassword(newPassword)
    if err != nil {
        return err
    }
    u.password = newPass
    u.updatedAt = time.Now()
    return nil
}
```

### Authentication Flow Architecture
JWT生成・検証・リフレッシュの完全実装

```go
// PATTERN: JWT handling with proper claims
type AuthClaims struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

// PATTERN: Token pair management
type TokenPair struct {
    AccessToken  string `json:"access_token"`
    RefreshToken string `json:"refresh_token"`
    ExpiresIn    int64  `json:"expires_in"`
}
```

### Tasks to be completed in order

```yaml
Task 1: Domain Layer実装
CREATE internal/domain/entity/user.go:
  - DEFINE User entity with business rules
  - IMPLEMENT factory methods with validation
  - ADD behavior methods (ChangePassword, UpdateProfile, etc.)

CREATE internal/domain/value_object/:
  - IMPLEMENT Email value object with validation
  - IMPLEMENT Password value object with hashing
  - IMPLEMENT UserID, Role value objects

CREATE internal/domain/repository/user_repository.go:
  - DEFINE repository interface (no implementation)
  - SPECIFY domain-focused methods

Task 2: Use Case Layer実装
CREATE internal/usecase/dto/:
  - DEFINE input/output DTOs for all operations
  - SEPARATE from domain entities

CREATE internal/usecase/interactor/auth_interactor.go:
  - IMPLEMENT Login use case
  - IMPLEMENT TokenRefresh use case
  - IMPLEMENT Logout use case
  - COORDINATE with domain and repository

CREATE internal/usecase/interactor/user_interactor.go:
  - IMPLEMENT CreateUser use case
  - IMPLEMENT GetUser, UpdateUser, DeleteUser
  - ENFORCE business rules through domain

Task 3: Infrastructure Layer実装
CREATE internal/infrastructure/database/connection.go:
  - SETUP GORM connection with PostgreSQL
  - CONFIGURE connection pooling
  - IMPLEMENT migration runner

CREATE internal/infrastructure/database/migration.go:
  - DEFINE user table schema
  - CREATE migration functions
  - HANDLE schema versioning

CREATE internal/infrastructure/config/:
  - IMPLEMENT configuration loading from env
  - VALIDATE required settings
  - PROVIDE defaults for development

Task 4: Adapter Layer実装
CREATE internal/adapter/repository/user_repository.go:
  - IMPLEMENT UserRepository interface
  - USE GORM for database operations
  - HANDLE CRUD operations with proper error handling

CREATE internal/adapter/gateway/jwt_gateway.go:
  - IMPLEMENT JWT generation with proper claims
  - IMPLEMENT JWT validation with error handling
  - MANAGE token expiration and refresh logic

CREATE internal/adapter/gateway/redis_gateway.go:
  - IMPLEMENT session storage in Redis
  - MANAGE token blacklisting
  - HANDLE TTL for different token types

Task 5: HTTP Layer実装
CREATE internal/adapter/controller/auth_controller.go:
  - IMPLEMENT POST /auth/login endpoint
  - IMPLEMENT POST /auth/refresh endpoint  
  - IMPLEMENT POST /auth/logout endpoint
  - BIND JSON requests and validate input

CREATE internal/adapter/controller/user_controller.go:
  - IMPLEMENT GET /users/{id} endpoint
  - IMPLEMENT PUT /users/{id} endpoint
  - IMPLEMENT DELETE /users/{id} endpoint
  - ENFORCE authentication and authorization

CREATE internal/infrastructure/server/middleware.go:
  - IMPLEMENT JWT authentication middleware
  - IMPLEMENT request logging middleware
  - IMPLEMENT error handling middleware
  - IMPLEMENT CORS middleware

Task 6: Application Wiring
MODIFY cmd/server/main.go:
  - SETUP dependency injection
  - WIRE all layers properly
  - INITIALIZE database and Redis connections
  - REGISTER routes and middleware

CREATE internal/infrastructure/server/router.go:
  - DEFINE all API routes
  - GROUP routes by functionality
  - APPLY middleware appropriately

Task 7: Testing Implementation
CREATE tests/unit/domain/:
  - TEST User entity business logic
  - TEST value object validation
  - ACHIEVE high test coverage for domain

CREATE tests/unit/usecase/:
  - TEST use case interactors with mocks
  - VERIFY error handling scenarios
  - TEST business rule enforcement

CREATE tests/integration/api_test.go:
  - TEST complete authentication flow
  - TEST user management endpoints
  - USE test database for isolation
```

### Task Details with Pseudocode

#### Task 1: Domain Layer核心実装
```go
// internal/domain/entity/user.go
package entity

import (
    "time"
    "auth-service/internal/domain/value_object"
)

type User struct {
    id        value_object.UserID
    email     value_object.Email
    password  value_object.Password
    role      value_object.Role
    profile   Profile
    createdAt time.Time
    updatedAt time.Time
}

// PATTERN: Factory method with validation
func NewUser(email, password string, role value_object.Role) (*User, error) {
    // CRITICAL: Domain validation before creation
    emailVO, err := value_object.NewEmail(email)
    if err != nil {
        return nil, err
    }
    
    passwordVO, err := value_object.NewPassword(password)
    if err != nil {
        return nil, err
    }
    
    return &User{
        id:        value_object.NewUserID(),
        email:     emailVO,
        password:  passwordVO,
        role:      role,
        createdAt: time.Now(),
        updatedAt: time.Now(),
    }, nil
}

// CRITICAL: Business behavior in entity
func (u *User) Authenticate(plainPassword string) bool {
    return u.password.Verify(plainPassword)
}

func (u *User) ChangePassword(oldPassword, newPassword string) error {
    if !u.password.Verify(oldPassword) {
        return ErrInvalidOldPassword
    }
    
    newPass, err := value_object.NewPassword(newPassword)
    if err != nil {
        return err
    }
    
    u.password = newPass
    u.updatedAt = time.Now()
    return nil
}
```

#### Task 3: Infrastructure Database
```go
// internal/infrastructure/database/connection.go
package database

import (
    "fmt"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

type DB struct {
    *gorm.DB
}

func NewConnection(config *Config) (*DB, error) {
    dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
        config.Host, config.User, config.Password, config.DBName, config.Port)
    
    // CRITICAL: GORM configuration for production
    gormConfig := &gorm.Config{
        Logger: logger.Default.LogMode(logger.Info),
    }
    
    db, err := gorm.Open(postgres.Open(dsn), gormConfig)
    if err != nil {
        return nil, fmt.Errorf("failed to connect database: %w", err)
    }
    
    // CRITICAL: Connection pool settings
    sqlDB, err := db.DB()
    if err != nil {
        return nil, err
    }
    
    sqlDB.SetMaxIdleConns(10)
    sqlDB.SetMaxOpenConns(100)
    sqlDB.SetConnMaxLifetime(time.Hour)
    
    return &DB{db}, nil
}
```

#### Task 4: JWT Gateway Implementation
```go
// internal/adapter/gateway/jwt_gateway.go
package gateway

import (
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type JWTGateway struct {
    secretKey []byte
    issuer    string
}

type AuthClaims struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

func (j *JWTGateway) GenerateTokenPair(userID, email, role string) (*TokenPair, error) {
    // CRITICAL: Access token (short-lived)
    accessClaims := &AuthClaims{
        UserID: userID,
        Email:  email,
        Role:   role,
        RegisteredClaims: jwt.RegisteredClaims{
            Issuer:    j.issuer,
            Subject:   userID,
            IssuedAt:  jwt.NewNumericDate(time.Now()),
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
        },
    }
    
    accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
    accessTokenString, err := accessToken.SignedString(j.secretKey)
    if err != nil {
        return nil, err
    }
    
    // CRITICAL: Refresh token (long-lived)
    refreshClaims := &jwt.RegisteredClaims{
        Issuer:    j.issuer,
        Subject:   userID,
        IssuedAt:  jwt.NewNumericDate(time.Now()),
        ExpiresAt: jwt.NewNumericDate(time.Now().Add(7 * 24 * time.Hour)),
    }
    
    refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
    refreshTokenString, err := refreshToken.SignedString(j.secretKey)
    if err != nil {
        return nil, err
    }
    
    return &TokenPair{
        AccessToken:  accessTokenString,
        RefreshToken: refreshTokenString,
        ExpiresIn:    900, // 15 minutes
    }, nil
}
```

### Integration Points
```yaml
DATABASE:
  - schema: auth_schema
  - table: users
  - indexes: email (unique), created_at, role
  - constraints: email format, password strength

REDIS:
  - session_storage: "session:{user_id}" with TTL
  - token_blacklist: "blacklist:{token_jti}" with TTL
  - refresh_tokens: "refresh:{user_id}" with TTL

AUTHENTICATION_FLOW:
  - login: validate credentials → generate token pair → store session
  - refresh: validate refresh token → generate new access token
  - logout: blacklist tokens → remove session

API_ENDPOINTS:
  - POST /auth/login: email, password → token pair
  - POST /auth/refresh: refresh_token → new access token
  - POST /auth/logout: access_token → success
  - GET /users/me: access_token → user profile
  - PUT /users/me: access_token, profile → updated profile
```

## Validation Loop

### Level 1: Domain Logic Validation
```bash
# ドメインロジックテスト
cd services/auth-service
go test ./internal/domain/... -v -cover

# Expected: All domain tests pass, coverage > 80%
# If failing: Fix business logic before proceeding
```

### Level 2: Use Case Testing
```bash
# ユースケーステスト（モック使用）
go test ./internal/usecase/... -v -cover

# Expected: All use case tests pass with mocked dependencies
# If failing: Fix use case logic and error handling
```

### Level 3: API Integration Testing
```bash
# データベース接続テスト
make test-db

# APIエンドポイントテスト
make test-api

# Expected: All API endpoints respond correctly
# If failing: Check database connection and route registration
```

### Level 4: Authentication Flow Testing
```bash
# 完全な認証フローテスト
curl -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'

# Expected: {"access_token":"...", "refresh_token":"...", "expires_in":900}

# トークン検証テスト
curl -X GET http://localhost:8001/users/me \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"

# Expected: User profile data
# If failing: Check JWT middleware and token validation
```

## Final validation Checklist
- [ ] 全単体テスト通過: `go test ./... -v`
- [ ] Linting成功: `golangci-lint run`
- [ ] ビルド成功: `go build ./cmd/server`
- [ ] データベース接続成功: Health check endpoint応答
- [ ] JWT認証フロー動作: Login → Token → Protected endpoint access
- [ ] エラーハンドリング適切: 不正な入力に対する適切なエラーレスポンス
- [ ] API文書化完了: docs/api.md に全エンドポイント記載
- [ ] セキュリティ要件充足: パスワードハッシュ化、JWT署名、HTTPS Ready

---

## Anti-Patterns to Avoid
- ❌ ドメインロジックをコントローラーに書く
- ❌ データベースの詳細をユースケース層に漏らす
- ❌ JWT secretをコードにハードコーディング
- ❌ パスワードを平文でログ出力する
- ❌ エラーレスポンスでスタックトレースを露出
- ❌ SQL injection脆弱性を残す
- ❌ Race conditionを引き起こすグローバル変数使用

**信頼度レベル: 8/10**
- クリーンアーキテクチャの確立されたパターンを使用
- JWT、GORM、Ginの成熟したライブラリ活用
- 段階的実装とテストで品質確保
- ただし、DDD実装の複雑さによる実装難度上昇あり