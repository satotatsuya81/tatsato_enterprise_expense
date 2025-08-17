name: "04 Integration Testing - E2E Testing & Performance Validation"
description: |
  統合テスト、E2Eテスト、パフォーマンステストを実装し、
  システム全体の品質保証と学習基盤の完成を確認します。

## Goal
認証システムの完全なテスト戦略を実装し、フロントエンドとバックエンドの統合、
パフォーマンス、セキュリティ要件を検証して学習基盤の品質を保証する。

## Why
- 実際のプロダクト開発におけるテスト戦略学習
- CI/CDパイプラインでの自動テスト実行
- E2Eテストによるユーザーエクスペリエンス検証
- パフォーマンス要件の達成確認
- セキュリティテストの基礎学習

## What
API統合テスト、E2Eテスト（Playwright）、パフォーマンステスト、
セキュリティテスト、負荷テスト、CI/CDテストパイプライン、
テストレポート生成、品質ゲート設定

### Success Criteria
- [ ] API統合テストが全て成功する
- [ ] E2Eテストで認証フローが完全に動作する
- [ ] パフォーマンス要件（レスポンス500ms以内）を満たす
- [ ] セキュリティテストで基本的な脆弱性がない
- [ ] 負荷テスト（100リクエスト/秒）をクリアする
- [ ] CI/CDパイプラインでテストが自動実行される
- [ ] テストカバレッジが要求水準を満たす
- [ ] 品質レポートが自動生成される

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Include these in your context window
- url: https://playwright.dev/docs/intro
  why: Playwright E2E testing patterns
  section: writing tests, page object model, test configuration

- url: https://github.com/features/actions
  why: GitHub Actions CI/CD testing patterns
  section: workflow syntax, matrix strategy, caching

- url: https://docs.docker.com/compose/
  why: Test environment orchestration
  section: test services, networking, environment variables

- url: https://k6.io/docs/
  why: Load testing with k6
  section: JavaScript scripting, metrics, thresholds

- url: https://owasp.org/www-project-zap/
  why: Security testing automation
  critical: API security scanning

- url: https://jestjs.io/docs/getting-started
  why: JavaScript testing framework
  section: mocking, async testing, setup/teardown

- url: https://golang.org/pkg/testing/
  why: Go testing patterns
  section: table tests, benchmarks, test helpers

- url: https://testcontainers.com/
  why: Integration testing with real databases
  section: PostgreSQL, Redis containers
```

### Current Codebase tree (after 03-frontend-auth-flow completion)
```bash
/Users/tatsuyasato/code/tatosato_keihi/
├── services/
│   └── auth-service/           # 完成した認証API
├── frontend/                   # 完成した認証フロー
├── infrastructure/
├── scripts/
├── .github/workflows/
└── docker-compose.yml
```

### Desired Codebase tree with files to be added
```bash
/Users/tatsuyasato/code/tatosato_keihi/
├── tests/
│   ├── integration/            # API統合テスト
│   │   ├── auth_test.go
│   │   ├── user_test.go
│   │   ├── setup_test.go
│   │   └── helpers/
│   │       ├── database.go
│   │       ├── api_client.go
│   │       └── test_data.go
│   ├── e2e/                    # E2Eテスト
│   │   ├── playwright.config.ts
│   │   ├── tests/
│   │   │   ├── auth-flow.spec.ts
│   │   │   ├── dashboard.spec.ts
│   │   │   ├── responsive.spec.ts
│   │   │   └── security.spec.ts
│   │   ├── fixtures/
│   │   │   └── test-data.json
│   │   ├── page-objects/
│   │   │   ├── login-page.ts
│   │   │   ├── dashboard-page.ts
│   │   │   └── base-page.ts
│   │   └── utils/
│   │       ├── auth-helper.ts
│   │       └── test-utils.ts
│   ├── performance/            # パフォーマンステスト
│   │   ├── k6/
│   │   │   ├── auth-load-test.js
│   │   │   ├── api-stress-test.js
│   │   │   └── config/
│   │   │       └── thresholds.js
│   │   └── lighthouse/
│   │       ├── lighthouse.config.js
│   │       └── run-audit.js
│   ├── security/               # セキュリティテスト
│   │   ├── zap/
│   │   │   ├── zap-baseline.py
│   │   │   └── zap-api-scan.py
│   │   └── manual/
│   │       ├── auth-security.md
│   │       └── owasp-checklist.md
│   └── reports/                # テストレポート
│       ├── coverage/
│       ├── e2e-results/
│       ├── performance/
│       └── security/
├── docker-compose.test.yml     # テスト環境用Docker構成
├── .github/workflows/
│   ├── test-integration.yml    # 統合テストワークフロー
│   ├── test-e2e.yml           # E2Eテストワークフロー
│   ├── test-performance.yml    # パフォーマンステスト
│   └── test-security.yml      # セキュリティテスト
├── scripts/
│   ├── test-setup.sh          # テスト環境セットアップ
│   ├── run-all-tests.sh       # 全テスト実行
│   ├── generate-reports.sh     # レポート生成
│   └── cleanup-test.sh        # テスト環境クリーンアップ
└── Makefile                   # テストターゲット追加
```

### Known Gotchas of our codebase & Library Quirks
```bash
# CRITICAL: Playwright browser installation
# 初回実行時にブラウザバイナリのダウンロードが必要
# Docker環境では適切なベースイメージ選択が重要

# CRITICAL: Testcontainers Docker requirements
# Docker daemon がテスト実行環境で動作している必要
# ポートの競合回避とクリーンアップが重要

# CRITICAL: Go integration test isolation
# 各テストでデータベースの初期化・クリーンアップが必要
# 並列実行時のテストデータ競合回避

# CRITICAL: k6 performance testing
# リソース制限下での正確な負荷測定
# ネットワーク遅延とローカル環境の影響

# CRITICAL: CI/CD環境でのテスト実行
# GitHub Actions runner の性能制限
# Docker layer caching の適切な設定

# CRITICAL: E2E test flakiness
# ネットワーク遅延、レンダリング待機の適切な処理
# テストデータの一意性確保

# CRITICAL: Security test false positives
# 開発環境特有の設定による誤検知
# 実際の脆弱性との区別が重要
```

## Implementation Blueprint

### Test Environment Architecture
Docker Composeベースの統合テスト環境

```yaml
# docker-compose.test.yml
services:
  postgres-test:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: expense_system_test
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_pass
    ports:
      - "5433:5432"

  redis-test:
    image: redis:7-alpine
    ports:
      - "6380:6379"

  auth-service-test:
    build: ./services/auth-service
    environment:
      - DATABASE_URL=postgres://test_user:test_pass@postgres-test:5432/expense_system_test
      - REDIS_URL=redis://redis-test:6379
      - JWT_SECRET=test_secret_key
    depends_on:
      - postgres-test
      - redis-test
    ports:
      - "8002:8001"
```

### E2E Testing Strategy
Playwright による包括的なユーザーフローテスト

```typescript
// Page Object Model pattern
class LoginPage {
  constructor(private page: Page) {}
  
  async login(email: string, password: string) {
    await this.page.fill('[data-testid=email-input]', email)
    await this.page.fill('[data-testid=password-input]', password)
    await this.page.click('[data-testid=login-button]')
    await this.page.waitForURL('/dashboard')
  }
}
```

### Tasks to be completed in order

```yaml
Task 1: 統合テスト環境構築
CREATE docker-compose.test.yml:
  - DEFINE isolated test database
  - CONFIGURE test Redis instance
  - SETUP test-specific environment variables
  - ENSURE port isolation from development

CREATE tests/integration/setup_test.go:
  - IMPLEMENT test database initialization
  - ADD test data seeding functions
  - CREATE database cleanup utilities
  - CONFIGURE test environment variables

CREATE tests/integration/helpers/:
  - IMPLEMENT database helper functions
  - CREATE API client for testing
  - ADD test data generators
  - PROVIDE assertion utilities

Task 2: API統合テスト実装
CREATE tests/integration/auth_test.go:
  - TEST complete authentication flow
  - VERIFY JWT token generation and validation
  - TEST token refresh mechanism
  - VALIDATE error handling scenarios

CREATE tests/integration/user_test.go:
  - TEST user CRUD operations
  - VERIFY authentication middleware
  - TEST authorization permissions
  - VALIDATE input validation and sanitization

ENHANCE services/auth-service/Makefile:
  - ADD test-integration target
  - CONFIGURE test database setup
  - IMPLEMENT coverage reporting
  - ADD test cleanup commands

Task 3: E2Eテスト基盤構築
INITIALIZE Playwright project:
  - INSTALL @playwright/test
  - CONFIGURE playwright.config.ts
  - SETUP multiple browser testing
  - CONFIGURE test environments

CREATE tests/e2e/page-objects/:
  - IMPLEMENT LoginPage class
  - CREATE DashboardPage class
  - ADD BasePage with common utilities
  - FOLLOW Page Object Model pattern

CREATE tests/e2e/utils/:
  - IMPLEMENT authentication helpers
  - ADD test data management
  - CREATE screenshot utilities
  - PROVIDE API mocking helpers

Task 4: 認証フローE2Eテスト
CREATE tests/e2e/tests/auth-flow.spec.ts:
  - TEST login with valid credentials
  - TEST login with invalid credentials
  - TEST logout functionality
  - TEST token expiration handling
  - TEST protected route access

CREATE tests/e2e/tests/dashboard.spec.ts:
  - TEST dashboard page rendering
  - VERIFY user information display
  - TEST navigation functionality
  - VALIDATE responsive behavior

Task 5: パフォーマンステスト実装
CREATE tests/performance/k6/auth-load-test.js:
  - IMPLEMENT login endpoint load testing
  - TEST 100 concurrent users
  - MEASURE response times
  - VALIDATE error rates under load

CREATE tests/performance/lighthouse/:
  - CONFIGURE Lighthouse CI
  - TEST Core Web Vitals
  - MEASURE accessibility scores
  - GENERATE performance reports

Task 6: セキュリティテスト基盤
CREATE tests/security/zap/:
  - IMPLEMENT OWASP ZAP automation
  - CONFIGURE API security scanning
  - ADD authentication bypass tests
  - GENERATE security reports

CREATE tests/security/manual/auth-security.md:
  - DOCUMENT manual security test cases
  - LIST OWASP Top 10 checklist
  - PROVIDE testing procedures
  - INCLUDE remediation guidelines

Task 7: CI/CDテストパイプライン
CREATE .github/workflows/test-integration.yml:
  - CONFIGURE database services
  - RUN Go integration tests
  - COLLECT coverage reports
  - UPLOAD test artifacts

CREATE .github/workflows/test-e2e.yml:
  - SETUP Playwright environment
  - RUN E2E tests on multiple browsers
  - CAPTURE screenshots on failures
  - GENERATE test reports

CREATE .github/workflows/test-performance.yml:
  - RUN k6 performance tests
  - EXECUTE Lighthouse audits
  - VALIDATE performance thresholds
  - PUBLISH performance reports

Task 8: テストレポート・品質ゲート
CREATE scripts/generate-reports.sh:
  - AGGREGATE all test results
  - GENERATE HTML reports
  - CALCULATE overall quality metrics
  - EXPORT CI/CD artifacts

MODIFY Makefile:
  - ADD comprehensive test targets
  - IMPLEMENT quality gates
  - CONFIGURE parallel test execution
  - ADD report generation commands
```

### Task Details with Pseudocode

#### Task 2: API統合テスト
```go
// tests/integration/auth_test.go
package integration

import (
    "testing"
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/suite"
)

type AuthTestSuite struct {
    suite.Suite
    server *httptest.Server
    client *http.Client
    db     *gorm.DB
}

func (suite *AuthTestSuite) SetupSuite() {
    // PATTERN: Test database initialization
    suite.db = setupTestDatabase()
    suite.server = setupTestServer(suite.db)
    suite.client = &http.Client{}
}

func (suite *AuthTestSuite) TearDownSuite() {
    // PATTERN: Cleanup test resources
    suite.server.Close()
    cleanupTestDatabase(suite.db)
}

func (suite *AuthTestSuite) TestLoginFlow() {
    // CRITICAL: Complete authentication flow testing
    testCases := []struct {
        name           string
        credentials    map[string]string
        expectedStatus int
        shouldHaveToken bool
    }{
        {
            name: "Valid credentials",
            credentials: map[string]string{
                "email":    "test@example.com",
                "password": "validpassword123",
            },
            expectedStatus: http.StatusOK,
            shouldHaveToken: true,
        },
        {
            name: "Invalid credentials",
            credentials: map[string]string{
                "email":    "test@example.com",
                "password": "wrongpassword",
            },
            expectedStatus: http.StatusUnauthorized,
            shouldHaveToken: false,
        },
    }
    
    for _, tc := range testCases {
        suite.Run(tc.name, func() {
            // PATTERN: Table-driven testing
            body, _ := json.Marshal(tc.credentials)
            resp, err := suite.client.Post(
                suite.server.URL+"/auth/login",
                "application/json",
                bytes.NewBuffer(body),
            )
            
            assert.NoError(suite.T(), err)
            assert.Equal(suite.T(), tc.expectedStatus, resp.StatusCode)
            
            if tc.shouldHaveToken {
                var result map[string]interface{}
                json.NewDecoder(resp.Body).Decode(&result)
                assert.Contains(suite.T(), result, "access_token")
                assert.Contains(suite.T(), result, "refresh_token")
            }
        })
    }
}
```

#### Task 4: E2E認証フローテスト
```typescript
// tests/e2e/tests/auth-flow.spec.ts
import { test, expect } from '@playwright/test'
import { LoginPage } from '../page-objects/login-page'
import { DashboardPage } from '../page-objects/dashboard-page'

test.describe('Authentication Flow', () => {
  let loginPage: LoginPage
  let dashboardPage: DashboardPage

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    dashboardPage = new DashboardPage(page)
  })

  test('should login with valid credentials and access dashboard', async ({ page }) => {
    // PATTERN: Page Object Model usage
    await page.goto('/auth/login')
    
    // CRITICAL: Wait for page load
    await expect(page.locator('[data-testid=login-form]')).toBeVisible()
    
    await loginPage.login('test@example.com', 'validpassword123')
    
    // PATTERN: Assert successful navigation
    await expect(page).toHaveURL('/dashboard')
    await expect(dashboardPage.welcomeMessage).toBeVisible()
    await expect(dashboardPage.welcomeMessage).toContainText('Welcome back')
  })

  test('should show error with invalid credentials', async ({ page }) => {
    await page.goto('/auth/login')
    
    await loginPage.login('test@example.com', 'wrongpassword')
    
    // PATTERN: Error message validation
    await expect(page.locator('[data-testid=error-message]')).toBeVisible()
    await expect(page.locator('[data-testid=error-message]')).toContainText('Invalid credentials')
    
    // CRITICAL: Should stay on login page
    await expect(page).toHaveURL('/auth/login')
  })

  test('should redirect to login when accessing protected route without auth', async ({ page }) => {
    // PATTERN: Protected route testing
    await page.goto('/dashboard')
    
    // CRITICAL: Should redirect to login
    await expect(page).toHaveURL('/auth/login')
  })

  test('should logout and redirect to login', async ({ page }) => {
    // PATTERN: Complete auth flow testing
    await page.goto('/auth/login')
    await loginPage.login('test@example.com', 'validpassword123')
    
    await dashboardPage.logout()
    
    // CRITICAL: Verify logout completion
    await expect(page).toHaveURL('/auth/login')
    
    // PATTERN: Verify cannot access protected route after logout
    await page.goto('/dashboard')
    await expect(page).toHaveURL('/auth/login')
  })
})
```

#### Task 5: k6負荷テスト
```javascript
// tests/performance/k6/auth-load-test.js
import http from 'k6/http'
import { check, sleep } from 'k6'
import { Rate } from 'k6/metrics'

// CRITICAL: Performance thresholds
export let options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp-up
    { duration: '5m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 100 },  // Scale to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],    // Error rate under 10%
    login_success_rate: ['rate>0.9'], // Login success rate over 90%
  },
}

const loginSuccessRate = new Rate('login_success_rate')

export default function () {
  // PATTERN: Load testing authentication endpoint
  const loginPayload = JSON.stringify({
    email: 'test@example.com',
    password: 'validpassword123',
  })

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  }

  // CRITICAL: Test login endpoint under load
  const loginResponse = http.post(
    'http://localhost:8001/auth/login',
    loginPayload,
    params
  )

  const loginSuccess = check(loginResponse, {
    'login status is 200': (r) => r.status === 200,
    'login response has token': (r) => {
      const body = JSON.parse(r.body)
      return body.access_token !== undefined
    },
    'login response time < 500ms': (r) => r.timings.duration < 500,
  })

  loginSuccessRate.add(loginSuccess)

  if (loginSuccess) {
    const token = JSON.parse(loginResponse.body).access_token
    
    // PATTERN: Test protected endpoint with token
    const profileResponse = http.get('http://localhost:8001/users/me', {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })

    check(profileResponse, {
      'profile status is 200': (r) => r.status === 200,
      'profile response time < 200ms': (r) => r.timings.duration < 200,
    })
  }

  sleep(1)
}
```

### Integration Points
```yaml
TEST_DATABASE:
  - isolation: separate test database per test suite
  - cleanup: automatic data cleanup after each test
  - seeding: consistent test data setup

CI_CD_INTEGRATION:
  - triggers: push to main, pull request creation
  - parallelization: multiple test types run simultaneously
  - reporting: test results published to GitHub

QUALITY_GATES:
  - coverage: minimum 80% for backend, 70% for frontend
  - performance: p95 response time < 500ms
  - security: no high-severity vulnerabilities
  - e2e: all critical user flows pass

MONITORING:
  - test_execution_time: track test suite performance
  - flaky_test_detection: identify and fix unstable tests
  - coverage_trends: monitor coverage over time
```

## Validation Loop

### Level 1: Unit Test Coverage
```bash
# Backend unit test coverage
cd services/auth-service
go test -cover ./...

# Frontend unit test coverage
cd frontend
npm run test:coverage

# Expected: Coverage > 80% backend, > 70% frontend
# If failing: Add missing test cases
```

### Level 2: Integration Test Execution
```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Run API integration tests
make test-integration

# Expected: All integration tests pass
# If failing: Check API implementation and database setup
```

### Level 3: E2E Test Validation
```bash
# Run E2E tests
npm run test:e2e

# Run specific test suites
npm run test:e2e -- auth-flow.spec.ts

# Expected: All E2E tests pass on multiple browsers
# If failing: Fix UI implementation and test stability
```

### Level 4: Performance Validation
```bash
# Run k6 load tests
k6 run tests/performance/k6/auth-load-test.js

# Run Lighthouse audit
npm run lighthouse

# Expected: Performance thresholds met, Lighthouse score > 90
# If failing: Optimize application performance
```

### Level 5: Security Validation
```bash
# Run OWASP ZAP security scan
python tests/security/zap/zap-api-scan.py

# Manual security checklist review
# Check tests/security/manual/auth-security.md

# Expected: No high-severity security issues
# If failing: Fix security vulnerabilities
```

## Final validation Checklist
- [ ] 全統合テスト成功: `make test-integration`
- [ ] E2Eテスト全通過: `npm run test:e2e`
- [ ] 負荷テスト成功: k6で100ユーザー/秒達成
- [ ] パフォーマンス要件: レスポンス500ms以内
- [ ] セキュリティスキャン: 高リスク脆弱性0件
- [ ] CI/CDパイプライン: 全ワークフロー成功
- [ ] テストカバレッジ: バックエンド80%以上、フロントエンド70%以上
- [ ] 品質レポート生成: HTML形式で結果可視化

---

## Anti-Patterns to Avoid
- ❌ テストデータの他テストとの競合
- ❌ E2Eテストでの過度な詳細検証
- ❌ パフォーマンステストでの非現実的な負荷設定
- ❌ セキュリティテストでの誤検知放置
- ❌ CI/CDでのテスト実行時間最適化不足
- ❌ 不安定なテストケースの放置
- ❌ テスト環境とプロダクション環境の乖離

**信頼度レベル: 7/10**
- 確立されたテストフレームワーク（Playwright、k6、Jest）使用
- Docker Composeによる再現可能なテスト環境
- CI/CDパイプラインでの自動テスト実行
- ただし、E2Eテストの安定性確保とパフォーマンステスト調整に注意が必要