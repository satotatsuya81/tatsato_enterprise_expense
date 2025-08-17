# 開発ガイド

## 目次
- [環境構築](#環境構築)
- [開発フロー](#開発フロー)
- [アーキテクチャガイド](#アーキテクチャガイド)
- [コーディング規約](#コーディング規約)
- [テスト戦略](#テスト戦略)
- [デバッグガイド](#デバッグガイド)

## 環境構築

### 必要なツール
```bash
# 必須
docker --version          # 24.0+
docker-compose --version  # 2.20+
go version                # 1.21+
node --version            # 18+
npm --version             # 9+

# 推奨
make --version            # GNU Make 4.0+
git --version             # 2.30+
curl --version            # 7.70+
```

### 初回セットアップ
```bash
# 1. リポジトリクローン
git clone <repository-url>
cd tatosato_keihi

# 2. 環境構築スクリプト実行
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. 全サービス起動
make up

# 4. ヘルスチェック
make health-check
```

### 開発サーバー起動
```bash
# コア サービスのみ起動（推奨）
docker-compose up -d postgres redis auth-service

# フロントエンド開発モード
cd frontend
npm install
npm run dev
```

## 開発フロー

### ブランチ戦略
```
main                    # 本番ブランチ
├── develop             # 開発統合ブランチ
├── feature/auth-api    # 機能開発ブランチ
├── feature/frontend-ui # 機能開発ブランチ
└── hotfix/security     # 緊急修正ブランチ
```

### コミット規約
```bash
# 形式: <type>(<scope>): <description>
feat(auth): add JWT token validation middleware
fix(frontend): resolve login form validation issue
docs(readme): update installation instructions
test(auth): add unit tests for password hashing
refactor(database): optimize user query performance
```

### プルリクエスト
1. **ブランチ作成**: `feature/機能名` または `fix/問題名`
2. **開発実装**: 小さなコミットで段階的に実装
3. **テスト実行**: 全テストがパスすることを確認
4. **コードレビュー**: 最低1名のレビューを必須とする
5. **マージ**: Squash merge で履歴を整理

## アーキテクチャガイド

### バックエンド構成
```
services/auth-service/
├── cmd/server/          # アプリケーションエントリーポイント
├── internal/
│   ├── domain/          # ビジネスロジック（エンティティ、値オブジェクト）
│   ├── usecase/         # アプリケーションサービス
│   ├── adapter/         # プレゼンテーション層（HTTP、gRPC）
│   └── infrastructure/  # データ永続化、外部API
├── pkg/                 # 共有ライブラリ
└── tests/               # テストコード
```

### 依存関係の方向
```
adapter → usecase → domain
infrastructure → usecase → domain
```

### Clean Architecture レイヤー
1. **Domain**: ビジネスルール、エンティティ
2. **Usecase**: アプリケーション固有ビジネスルール
3. **Adapter**: UI、Web、外部インターフェース
4. **Infrastructure**: DB、Framework、外部サービス

### フロントエンド構成
```
frontend/src/
├── app/                 # Next.js App Router
│   ├── (auth)/         # 認証関連ページ
│   ├── dashboard/      # ダッシュボード
│   ├── globals.css     # グローバルスタイル
│   └── layout.tsx      # ルートレイアウト
├── components/          # 再利用可能コンポーネント
│   ├── ui/             # shadcn/ui コンポーネント
│   └── forms/          # フォームコンポーネント
├── lib/                 # ユーティリティ関数
├── hooks/              # カスタムHooks
├── store/              # Zustand状態管理
└── types/              # TypeScript型定義
```

## コーディング規約

### Go 規約
```go
// ✅ Good: 明確な命名、エラーハンドリング
func (s *AuthService) ValidateToken(ctx context.Context, token string) (*User, error) {
    if token == "" {
        return nil, errors.New("token is required")
    }
    
    claims, err := s.jwtService.ParseToken(token)
    if err != nil {
        return nil, fmt.Errorf("invalid token: %w", err)
    }
    
    return s.userRepo.FindByID(ctx, claims.UserID)
}

// ❌ Bad: 曖昧な命名、エラー無視
func (s *AuthService) validate(t string) *User {
    claims, _ := s.jwtService.ParseToken(t)
    user, _ := s.userRepo.FindByID(context.Background(), claims.UserID)
    return user
}
```

### TypeScript 規約
```typescript
// ✅ Good: 型安全、明確なインターフェース
interface LoginRequest {
  email: string;
  password: string;
}

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

const login = async (credentials: LoginRequest): Promise<AuthResponse> => {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(credentials),
  });
  
  if (!response.ok) {
    throw new Error('Login failed');
  }
  
  return response.json();
};

// ❌ Bad: any使用、エラーハンドリング不足
const login = async (data: any) => {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify(data),
  });
  return response.json();
};
```

### ディレクトリ命名
- `kebab-case`: ディレクトリ、ファイル名
- `PascalCase`: コンポーネント、型
- `camelCase`: 変数、関数
- `SCREAMING_SNAKE_CASE`: 定数

## テスト戦略

### テストピラミッド
```
     /\
    /E2\     少数：ブラウザ自動化テスト
   /____\
  /      \
 / 統合   \   中程度：API、DB連携テスト
/________\
/          \
/  単体    \  多数：ビジネスロジックテスト
/__________\
```

### Go テスト
```go
// 単体テスト例
func TestPasswordService_HashPassword(t *testing.T) {
    service := NewPasswordService()
    
    tests := []struct {
        name     string
        password string
        wantErr  bool
    }{
        {"valid password", "password123", false},
        {"empty password", "", true},
        {"short password", "123", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            hash, err := service.HashPassword(tt.password)
            
            if tt.wantErr {
                assert.Error(t, err)
                assert.Empty(t, hash)
            } else {
                assert.NoError(t, err)
                assert.NotEmpty(t, hash)
                assert.True(t, service.VerifyPassword(tt.password, hash))
            }
        })
    }
}
```

### Frontend テスト
```typescript
// Jest + Testing Library例
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { LoginForm } from './LoginForm';

describe('LoginForm', () => {
  it('should submit valid credentials', async () => {
    const mockOnSubmit = jest.fn();
    render(<LoginForm onSubmit={mockOnSubmit} />);
    
    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'test@example.com' }
    });
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    });
    
    fireEvent.click(screen.getByRole('button', { name: /login/i }));
    
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123'
      });
    });
  });
});
```

### テスト実行
```bash
# バックエンド
cd services/auth-service
go test -v -race -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# フロントエンド
cd frontend
npm test
npm run test:coverage

# 統合テスト
./scripts/test-integration.sh

# 全テスト
make test
```

## デバッグガイド

### ログ確認
```bash
# サービスログ
docker-compose logs -f auth-service
docker-compose logs -f postgres
docker-compose logs -f redis

# アプリケーションログ（開発モード）
cd services/auth-service && go run cmd/server/main.go

# フロントエンドログ
cd frontend && npm run dev
```

### データベースデバッグ
```bash
# PostgreSQL接続
docker-compose exec postgres psql -U postgres -d expense_system

# スキーマ確認
\dn

# テーブル確認
\dt auth_schema.*

# データ確認
SELECT * FROM auth_schema.users;
```

### Redis デバッグ
```bash
# Redis CLI
docker-compose exec redis redis-cli

# キー一覧
KEYS *

# 特定キー確認
GET auth:session:123
```

### API テスト
```bash
# ヘルスチェック
curl http://localhost:8001/health

# 認証テスト
curl -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'
```

### パフォーマンス監視
```bash
# CPU/メモリ使用量
docker stats

# データベースクエリ監視
docker-compose exec postgres psql -U postgres -d expense_system \
  -c "SELECT query, calls, total_time FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. Port Already in Use
```bash
# ポート使用確認
lsof -i :8001

# プロセス終了
kill -9 <PID>

# Docker コンテナ停止
docker-compose down
```

#### 2. Go Module Issues
```bash
# モジュール同期
go mod tidy

# ベンダー更新
go mod vendor

# キャッシュクリア
go clean -modcache
```

#### 3. Frontend Build Errors
```bash
# 依存関係再インストール
rm -rf node_modules package-lock.json
npm install

# TypeScript エラー確認
npm run type-check
```

#### 4. Database Connection Issues
```bash
# データベース再作成
docker-compose down -v
docker-compose up -d postgres

# 初期化スクリプト確認
docker-compose exec postgres psql -U postgres -d expense_system -c "\i /docker-entrypoint-initdb.d/init.sql"
```

---

**更新日**: 2025-08-17  
**バージョン**: 1.0.0