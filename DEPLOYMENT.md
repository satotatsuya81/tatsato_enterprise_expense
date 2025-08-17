# デプロイメントガイド

## 目次
- [デプロイメント戦略](#デプロイメント戦略)
- [環境構成](#環境構成)
- [Docker 本番デプロイ](#docker-本番デプロイ)
- [AWS ECS デプロイ](#aws-ecs-デプロイ)
- [監視・ログ](#監視ログ)
- [トラブルシューティング](#トラブルシューティング)

## デプロイメント戦略

### 環境
- **開発環境 (Development)**: ローカル Docker Compose
- **ステージング環境 (Staging)**: AWS ECS Fargate
- **本番環境 (Production)**: AWS ECS Fargate + ALB + RDS

### デプロイフロー
```
開発 → GitHub Push → CI/CD → ステージング → 承認 → 本番
```

## 環境構成

### 開発環境 (Local)
```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: expense_system
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
  
  redis:
    image: redis:7-alpine
  
  auth-service:
    build:
      context: ./services/auth-service
      target: development
    environment:
      - GIN_MODE=debug
      - LOG_LEVEL=debug
```

### 本番環境 (Production)
```yaml
# docker-compose.prod.yml
services:
  auth-service:
    build:
      context: ./services/auth-service
      target: production
    environment:
      - GIN_MODE=release
      - LOG_LEVEL=info
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
```

## Docker 本番デプロイ

### 1. イメージビルド
```bash
# 本番用イメージビルド
./scripts/build-all.sh --production

# イメージ確認
docker images | grep -E "(auth-service|frontend)"
```

### 2. 環境変数設定
```bash
# .env.production
DATABASE_URL=postgres://user:pass@rds-endpoint:5432/db
REDIS_URL=redis://elasticache-endpoint:6379
JWT_SECRET=your-super-secret-jwt-key
NEXTAUTH_SECRET=your-nextauth-secret
CORS_ALLOWED_ORIGINS=https://yourdomain.com
```

### 3. 本番デプロイ実行
```bash
# 本番環境起動
docker-compose -f docker-compose.prod.yml up -d

# ヘルスチェック
curl https://api.yourdomain.com/health
curl https://yourdomain.com
```

### 4. SSL/TLS 設定
```nginx
# infrastructure/nginx/nginx.conf
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;
    
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS;
    
    location / {
        proxy_pass http://auth-service:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## AWS ECS デプロイ

### 1. ECR プッシュ
```bash
# ECR ログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com

# イメージタグ
docker tag auth-service:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/expense-auth-service:latest
docker tag frontend:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/expense-frontend:latest

# プッシュ
docker push 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/expense-auth-service:latest
docker push 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/expense-frontend:latest
```

### 2. ECS タスク定義
```json
{
  "family": "expense-auth-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "auth-service",
      "image": "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/expense-auth-service:latest",
      "portMappings": [
        {
          "containerPort": 8001,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "GIN_MODE",
          "value": "release"
        },
        {
          "name": "LOG_LEVEL",
          "value": "info"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:expense-system/database-url"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:expense-system/jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/expense-auth-service",
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:8001/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

### 3. ECS サービス設定
```json
{
  "serviceName": "expense-auth-service",
  "cluster": "expense-system-cluster",
  "taskDefinition": "expense-auth-service:1",
  "desiredCount": 2,
  "launchType": "FARGATE",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "subnet-12345678",
        "subnet-87654321"
      ],
      "securityGroups": [
        "sg-12345678"
      ],
      "assignPublicIp": "DISABLED"
    }
  },
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/expense-auth-tg/1234567890123456",
      "containerName": "auth-service",
      "containerPort": 8001
    }
  ],
  "serviceTags": [
    {
      "key": "Environment",
      "value": "production"
    },
    {
      "key": "Project",
      "value": "expense-system"
    }
  ]
}
```

### 4. RDS 設定
```bash
# RDS インスタンス作成
aws rds create-db-instance \
  --db-instance-identifier expense-system-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username postgres \
  --master-user-password YourSecurePassword \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-12345678 \
  --db-subnet-group-name expense-db-subnet-group \
  --backup-retention-period 7 \
  --storage-encrypted \
  --multi-az

# ElastiCache Redis 作成
aws elasticache create-cache-cluster \
  --cache-cluster-id expense-system-redis \
  --engine redis \
  --cache-node-type cache.t3.micro \
  --num-cache-nodes 1 \
  --security-group-ids sg-12345678 \
  --subnet-group-name expense-cache-subnet-group
```

## GitHub Actions CI/CD

### ワークフロー設定
```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AWS_REGION: ap-northeast-1
  ECR_REGISTRY: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com
  
jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2
      
    - name: Build and push auth-service
      env:
        ECR_REPOSITORY: expense-auth-service
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
          --target production ./services/auth-service
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
          $ECR_REGISTRY/$ECR_REPOSITORY:latest
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
        
    - name: Deploy to ECS
      run: |
        aws ecs update-service \
          --cluster expense-system-cluster \
          --service expense-auth-service \
          --force-new-deployment
```

## 監視・ログ

### CloudWatch Logs
```bash
# ログストリーム確認
aws logs describe-log-streams \
  --log-group-name /ecs/expense-auth-service

# ログ確認
aws logs filter-log-events \
  --log-group-name /ecs/expense-auth-service \
  --start-time $(date -d '1 hour ago' +%s)000
```

### CloudWatch Metrics
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "expense-auth-service"],
          [".", "MemoryUtilization", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "ap-northeast-1",
        "title": "ECS Service Metrics"
      }
    }
  ]
}
```

### アラート設定
```json
{
  "AlarmName": "expense-auth-service-high-cpu",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 2,
  "MetricName": "CPUUtilization",
  "Namespace": "AWS/ECS",
  "Period": 300,
  "Statistic": "Average",
  "Threshold": 80,
  "ActionsEnabled": true,
  "AlarmActions": [
    "arn:aws:sns:ap-northeast-1:123456789012:expense-system-alerts"
  ],
  "AlarmDescription": "Alarm when auth-service CPU exceeds 80%",
  "Dimensions": [
    {
      "Name": "ServiceName",
      "Value": "expense-auth-service"
    }
  ]
}
```

## ヘルスチェック

### アプリケーションヘルスチェック
```go
// services/auth-service/internal/adapter/http/health.go
func (h *HealthHandler) Check(c *gin.Context) {
    checks := map[string]string{
        "status":      "ok",
        "timestamp":   time.Now().UTC().Format(time.RFC3339),
        "version":     h.version,
        "database":    h.checkDatabase(),
        "redis":       h.checkRedis(),
        "memory":      h.checkMemory(),
    }
    
    if checks["database"] != "ok" || checks["redis"] != "ok" {
        c.JSON(http.StatusServiceUnavailable, checks)
        return
    }
    
    c.JSON(http.StatusOK, checks)
}
```

### ロードバランサーヘルスチェック
```yaml
# ALB Target Group Health Check
HealthCheckEnabled: true
HealthCheckPath: "/health"
HealthCheckProtocol: "HTTP"
HealthCheckIntervalSeconds: 30
HealthCheckTimeoutSeconds: 5
HealthyThresholdCount: 2
UnhealthyThresholdCount: 3
```

## セキュリティ

### 環境変数管理
```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name expense-system/database-url \
  --description "Database connection URL for expense system" \
  --secret-string "postgres://username:password@rds-endpoint:5432/expense_system"

aws secretsmanager create-secret \
  --name expense-system/jwt-secret \
  --description "JWT signing secret for expense system" \
  --secret-string "your-super-secret-jwt-key"
```

### IAM ロール
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:expense-system/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:ap-northeast-1:123456789012:log-group:/ecs/expense-*"
      ]
    }
  ]
}
```

## バックアップ・復旧

### データベースバックアップ
```bash
# RDS 自動バックアップ
aws rds modify-db-instance \
  --db-instance-identifier expense-system-db \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00"

# 手動スナップショット
aws rds create-db-snapshot \
  --db-instance-identifier expense-system-db \
  --db-snapshot-identifier expense-system-db-snapshot-$(date +%Y%m%d%H%M%S)
```

### 災害復旧手順
1. **インシデント検知**: CloudWatch アラート
2. **影響範囲確認**: サービス状況、ユーザー影響
3. **復旧作業**: 
   - データベース復旧
   - アプリケーション再デプロイ
   - 動作確認
4. **事後分析**: インシデントレポート作成

## トラブルシューティング

### よくある問題

#### 1. ECS タスク起動失敗
```bash
# タスク状況確認
aws ecs describe-tasks \
  --cluster expense-system-cluster \
  --tasks <task-arn>

# タスク停止理由確認
aws ecs describe-tasks \
  --cluster expense-system-cluster \
  --tasks <task-arn> \
  --query 'tasks[0].stoppedReason'
```

#### 2. データベース接続エラー
```bash
# RDS 状況確認
aws rds describe-db-instances \
  --db-instance-identifier expense-system-db

# セキュリティグループ確認
aws ec2 describe-security-groups \
  --group-ids sg-12345678
```

#### 3. ロードバランサーヘルスチェック失敗
```bash
# ターゲットグループ状況確認
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/expense-auth-tg/1234567890123456
```

#### 4. パフォーマンス問題
```bash
# CPU/メモリメトリクス確認
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=expense-auth-service \
  --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

---

**更新日**: 2025-08-17  
**バージョン**: 1.0.0