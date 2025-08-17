# Enterprise Expense System

学習用経費精算システム - Go + Next.js マイクロサービスアーキテクチャ

## 概要

このプロジェクトは、金融系システムの実践的な学習を目的とした経費精算システムです。
DDD/クリーンアーキテクチャ、マイクロサービス、BFF、CI/CDの実装を通じて、
現代的なソフトウェア開発手法を習得します。

## アーキテクチャ

### バックエンド
- **言語**: Go 1.21+
- **アーキテクチャ**: Clean Architecture + DDD
- **フレームワーク**: Gin, gRPC
- **データベース**: PostgreSQL 15+
- **キャッシュ**: Redis
- **認証**: JWT (RS256)

### フロントエンド
- **フレームワーク**: Next.js 14 (App Router)
- **言語**: TypeScript
- **状態管理**: Zustand
- **UIライブラリ**: shadcn/ui + Tailwind CSS
- **WebSocket**: Socket.io Client

### インフラストラクチャ
- **コンテナ**: Docker + Docker Compose
- **オーケストレーション**: AWS ECS (将来)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **監視**: AWS CloudWatch (将来)

## サービス構成

```
├── services/
│   ├── auth-service/        # 認証・認可サービス
│   ├── bff-service/         # Backend for Frontend
│   ├── expense-service/     # 経費管理サービス (将来)
│   └── workflow-service/    # ワークフローサービス (将来)
├── frontend/                # Next.js フロントエンド
└── infrastructure/          # インフラ設定
```

## クイックスタート

### 前提条件

- Docker & Docker Compose
- Go 1.21+
- Node.js 18+
- Make

### 環境構築

1. **リポジトリクローン**
   ```bash
   git clone <repository-url>
   cd tatosato_keihi
   ```

2. **環境起動**
   ```bash
   make up
   ```

3. **ヘルスチェック**
   ```bash
   make health-check
   ```

4. **サービス停止**
   ```bash
   make down
   ```

## 開発コマンド

### 全体管理
```bash
make help              # ヘルプ表示
make up                # 全サービス起動
make down              # 全サービス停止
make build             # 全サービスビルド
make test              # 全テスト実行
make lint              # 全Linting実行
make clean             # クリーンアップ
```

### 個別サービス
```bash
# 認証サービス
make -C services/auth-service test
make -C services/auth-service lint
make -C services/auth-service build

# フロントエンド
make -C frontend test
make -C frontend lint
make -C frontend build
```

## API エンドポイント

### 認証サービス (Port: 8001)
- `GET /health` - ヘルスチェック
- `POST /auth/login` - ログイン
- `POST /auth/refresh` - トークンリフレッシュ
- `POST /auth/logout` - ログアウト
- `GET /users/me` - ユーザー情報取得

### フロントエンド (Port: 3000)
- `http://localhost:3000` - メインアプリケーション
- `http://localhost:3000/auth/login` - ログイン画面
- `http://localhost:3000/dashboard` - ダッシュボード

## 学習目標

### Phase 1 (Month 1)
- [x] クリーンアーキテクチャの実装
- [x] JWT認証システム（基盤）
- [x] Next.js 14 App Router（セットアップ）
- [x] Docker環境構築
- [x] CI/CDパイプライン

### Phase 2 (Month 2)
- [ ] DDD実装（集約、イベント）
- [ ] マイクロサービス間通信
- [ ] ワークフローエンジン
- [ ] リアルタイム通知

### Phase 3 (Month 3)
- [ ] 統合テスト
- [ ] パフォーマンス最適化
- [ ] セキュリティ強化
- [ ] E2Eテスト

## プロジェクト構造

```
/
├── services/                    # マイクロサービス
│   └── auth-service/
│       ├── cmd/                 # アプリケーションエントリーポイント
│       ├── internal/            # プライベートコード
│       │   ├── domain/          # ドメイン層
│       │   ├── usecase/         # アプリケーション層
│       │   ├── adapter/         # アダプター層
│       │   └── infrastructure/  # インフラ層
│       ├── pkg/                 # パブリックライブラリ
│       └── tests/               # テスト
├── frontend/                    # Next.js アプリケーション
│   └── src/
│       ├── app/                 # App Router
│       ├── components/          # UIコンポーネント
│       ├── lib/                 # ユーティリティ
│       └── types/               # TypeScript型定義
├── infrastructure/              # インフラ設定
│   ├── docker/                  # Docker設定
│   └── terraform/               # IaC (将来)
└── scripts/                     # 開発スクリプト
```

## 技術スタック詳細

### 認証・認可
- JWT (JSON Web Token) による認証
- RBAC (Role-Based Access Control) による認可
- リフレッシュトークンによるセッション管理

### データベース設計
- PostgreSQL スキーマ分離
- マイクロサービス毎の論理分離
- GORM v2 による ORM

### フロントエンド
- Server Components と Client Components の使い分け
- TypeScript strict mode
- shadcn/ui による一貫したUI
- Zustand による軽量状態管理

## 品質保証

### テスト戦略
- **単体テスト**: 80%以上のカバレッジ
- **統合テスト**: API間の連携テスト
- **E2Eテスト**: Playwright による自動化

### CI/CD
- GitHub Actions による自動化
- Lint + Test + Build の並列実行
- セキュリティスキャン
- パフォーマンステスト

## トラブルシューティング

### 一般的な問題

1. **Docker起動失敗**
   ```bash
   # ポート競合確認
   lsof -i :5432 -i :6379 -i :8001 -i :3000
   
   # Docker ログ確認
   docker-compose logs [service-name]
   ```

2. **データベース接続エラー**
   ```bash
   # PostgreSQL接続確認
   docker-compose exec postgres psql -U postgres -d expense_system
   ```

3. **フロントエンドビルドエラー**
   ```bash
   # 依存関係再インストール
   cd frontend && rm -rf node_modules package-lock.json && npm install
   ```

## コントリビューション

このプロジェクトは学習目的のため、外部からのコントリビューションは受け付けていません。

## ライセンス

このプロジェクトは学習目的で作成されており、商用利用は想定していません。

## 学習リソース

- [実践ドメイン駆動設計](https://www.amazon.co.jp/dp/479813161X)
- [マイクロサービスパターン](https://www.amazon.co.jp/dp/4295004928)
- [Clean Architecture 達人に学ぶソフトウェアの構造と設計](https://www.amazon.co.jp/dp/4048930656)
- [Three Dots Labs - Go DDD Example](https://threedots.tech/post/ddd-cqrs-clean-architecture-combined/)

---

**開発状況**: Phase 1 基盤構築完了 ✅ → Phase 2 認証実装開始 🚧

## 最新の実装状況

### ✅ 完了済み（2025-08-17）
- **基盤構築**: Docker Compose環境、PostgreSQL、Redis
- **Auth Service**: Go + Gin ベースサービス、ヘルスチェック対応
- **フロントエンド**: Next.js 14 プロジェクト、TypeScript設定
- **CI/CD**: GitHub Actions パイプライン設定
- **開発環境**: Makefile統合、開発スクリプト

### 🚧 進行中
- JWT認証フローの実装
- ユーザー登録・ログイン API
- パスワードハッシュ化（bcrypt）
- フロントエンド認証UI

### 📋 次のステップ
Month 1 Week 3-4で以下を実装予定:
- 認証APIの完全実装
- フロントエンド認証フロー
- セキュリティ強化
- 統合テスト充実化