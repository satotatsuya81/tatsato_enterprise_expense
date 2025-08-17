# セキュリティガイド

## 目次
- [セキュリティ原則](#セキュリティ原則)
- [認証・認可](#認証認可)
- [データ保護](#データ保護)
- [ネットワークセキュリティ](#ネットワークセキュリティ)
- [脆弱性対策](#脆弱性対策)
- [監査・ログ](#監査ログ)
- [セキュリティテスト](#セキュリティテスト)

## セキュリティ原則

### Defense in Depth（多層防御）
```
┌─────────────────────────┐
│   Application Layer     │  入力検証、認証、認可
├─────────────────────────┤
│   Transport Layer       │  TLS/SSL、証明書管理
├─────────────────────────┤
│   Network Layer         │  ファイアウォール、VPC
├─────────────────────────┤
│   Infrastructure Layer  │  OS、コンテナセキュリティ
└─────────────────────────┘
```

### セキュリティバイデザイン
- **最小権限の原則**: 必要最小限のアクセス権限のみ付与
- **デフォルトで拒否**: 明示的に許可されない限り拒否
- **深層防御**: 複数のセキュリティレイヤーで保護
- **失敗時の安全**: システム障害時も安全な状態を維持

## 認証・認可

### JWT 実装
```go
// JWT Token 生成
func (j *JWTService) GenerateTokenPair(userID string, roles []string) (*TokenPair, error) {
    // Access Token (短期間: 15分)
    accessClaims := &Claims{
        UserID: userID,
        Roles:  roles,
        StandardClaims: jwt.StandardClaims{
            ExpiresAt: time.Now().Add(15 * time.Minute).Unix(),
            IssuedAt:  time.Now().Unix(),
            Issuer:    "expense-system",
            Subject:   userID,
        },
    }
    
    accessToken := jwt.NewWithClaims(jwt.SigningMethodRS256, accessClaims)
    accessTokenString, err := accessToken.SignedString(j.privateKey)
    if err != nil {
        return nil, fmt.Errorf("failed to sign access token: %w", err)
    }
    
    // Refresh Token (長期間: 7日)
    refreshClaims := &RefreshClaims{
        UserID: userID,
        StandardClaims: jwt.StandardClaims{
            ExpiresAt: time.Now().Add(7 * 24 * time.Hour).Unix(),
            IssuedAt:  time.Now().Unix(),
            Issuer:    "expense-system",
            Subject:   userID,
        },
    }
    
    refreshToken := jwt.NewWithClaims(jwt.SigningMethodRS256, refreshClaims)
    refreshTokenString, err := refreshToken.SignedString(j.privateKey)
    if err != nil {
        return nil, fmt.Errorf("failed to sign refresh token: %w", err)
    }
    
    return &TokenPair{
        AccessToken:  accessTokenString,
        RefreshToken: refreshTokenString,
        ExpiresIn:    900, // 15分
    }, nil
}

// Token 検証
func (j *JWTService) ValidateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        return j.publicKey, nil
    })
    
    if err != nil {
        return nil, fmt.Errorf("failed to parse token: %w", err)
    }
    
    if !token.Valid {
        return nil, errors.New("invalid token")
    }
    
    claims, ok := token.Claims.(*Claims)
    if !ok {
        return nil, errors.New("invalid token claims")
    }
    
    return claims, nil
}
```

### パスワードセキュリティ
```go
// bcrypt によるパスワードハッシュ化
func (p *PasswordService) HashPassword(password string) (string, error) {
    // パスワード強度チェック
    if err := p.validatePasswordStrength(password); err != nil {
        return "", err
    }
    
    // bcrypt ハッシュ化 (cost: 14)
    hashedBytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
    if err != nil {
        return "", fmt.Errorf("failed to hash password: %w", err)
    }
    
    return string(hashedBytes), nil
}

func (p *PasswordService) validatePasswordStrength(password string) error {
    if len(password) < 8 {
        return errors.New("password must be at least 8 characters")
    }
    
    var (
        hasUpper   = regexp.MustCompile(`[A-Z]`).MatchString(password)
        hasLower   = regexp.MustCompile(`[a-z]`).MatchString(password)
        hasNumber  = regexp.MustCompile(`[0-9]`).MatchString(password)
        hasSpecial = regexp.MustCompile(`[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]`).MatchString(password)
    )
    
    score := 0
    if hasUpper { score++ }
    if hasLower { score++ }
    if hasNumber { score++ }
    if hasSpecial { score++ }
    
    if score < 3 {
        return errors.New("password must contain at least 3 of: uppercase, lowercase, number, special character")
    }
    
    return nil
}

// パスワード検証
func (p *PasswordService) VerifyPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
```

### RBAC (Role-Based Access Control)
```go
// 権限チェックミドルウェア
func (m *AuthMiddleware) RequireRole(requiredRoles ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        // JWT トークンから claims 取得
        claims, exists := c.Get("claims")
        if !exists {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
            c.Abort()
            return
        }
        
        userClaims, ok := claims.(*Claims)
        if !ok {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid claims"})
            c.Abort()
            return
        }
        
        // ロール確認
        hasRequiredRole := false
        for _, userRole := range userClaims.Roles {
            for _, requiredRole := range requiredRoles {
                if userRole == requiredRole {
                    hasRequiredRole = true
                    break
                }
            }
            if hasRequiredRole {
                break
            }
        }
        
        if !hasRequiredRole {
            c.JSON(http.StatusForbidden, gin.H{"error": "insufficient permissions"})
            c.Abort()
            return
        }
        
        c.Next()
    }
}

// 使用例
router.GET("/admin/users", 
    authMiddleware.Authenticate(),
    authMiddleware.RequireRole("admin", "super_admin"),
    userHandler.ListUsers,
)
```

## データ保護

### 機密データ暗号化
```go
// AES-256-GCM による暗号化
func (e *EncryptionService) Encrypt(plaintext string) (string, error) {
    block, err := aes.NewCipher(e.key)
    if err != nil {
        return "", fmt.Errorf("failed to create cipher: %w", err)
    }
    
    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return "", fmt.Errorf("failed to create GCM: %w", err)
    }
    
    nonce := make([]byte, gcm.NonceSize())
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        return "", fmt.Errorf("failed to generate nonce: %w", err)
    }
    
    ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
    return base64.StdEncoding.EncodeToString(ciphertext), nil
}

func (e *EncryptionService) Decrypt(ciphertext string) (string, error) {
    data, err := base64.StdEncoding.DecodeString(ciphertext)
    if err != nil {
        return "", fmt.Errorf("failed to decode base64: %w", err)
    }
    
    block, err := aes.NewCipher(e.key)
    if err != nil {
        return "", fmt.Errorf("failed to create cipher: %w", err)
    }
    
    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return "", fmt.Errorf("failed to create GCM: %w", err)
    }
    
    nonceSize := gcm.NonceSize()
    if len(data) < nonceSize {
        return "", errors.New("ciphertext too short")
    }
    
    nonce, ciphertext := data[:nonceSize], data[nonceSize:]
    plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
    if err != nil {
        return "", fmt.Errorf("failed to decrypt: %w", err)
    }
    
    return string(plaintext), nil
}
```

### データベースセキュリティ
```sql
-- 機密データ暗号化例
CREATE TABLE auth_schema.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    -- 個人情報は暗号化して保存
    encrypted_personal_info TEXT,
    salt VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 行レベルセキュリティ (RLS)
ALTER TABLE expense_schema.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_expenses ON expense_schema.expenses
    FOR ALL TO authenticated_users
    USING (user_id = current_setting('app.current_user_id')::UUID);
```

### PII データ保護
```go
// PII マスキング
func (m *PIIMasker) MaskEmail(email string) string {
    parts := strings.Split(email, "@")
    if len(parts) != 2 {
        return "***@***.***"
    }
    
    username := parts[0]
    domain := parts[1]
    
    maskedUsername := ""
    if len(username) <= 2 {
        maskedUsername = strings.Repeat("*", len(username))
    } else {
        maskedUsername = string(username[0]) + strings.Repeat("*", len(username)-2) + string(username[len(username)-1])
    }
    
    return maskedUsername + "@" + domain
}

func (m *PIIMasker) MaskCreditCard(cardNumber string) string {
    if len(cardNumber) < 4 {
        return strings.Repeat("*", len(cardNumber))
    }
    return strings.Repeat("*", len(cardNumber)-4) + cardNumber[len(cardNumber)-4:]
}
```

## ネットワークセキュリティ

### TLS/SSL 設定
```nginx
# Nginx SSL 設定
server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    # SSL 証明書
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # セキュリティ設定
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # セキュリティヘッダー
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
}
```

### CORS 設定
```go
// CORS ミドルウェア
func CORSMiddleware() gin.HandlerFunc {
    return gin.HandlerFunc(func(c *gin.Context) {
        origin := c.Request.Header.Get("Origin")
        
        // 許可されたオリジンチェック
        allowedOrigins := []string{
            "https://app.example.com",
            "https://admin.example.com",
        }
        
        isAllowed := false
        for _, allowedOrigin := range allowedOrigins {
            if origin == allowedOrigin {
                isAllowed = true
                break
            }
        }
        
        if isAllowed {
            c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
            c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
            c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
            c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")
        }
        
        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }
        
        c.Next()
    })
}
```

### Rate Limiting
```go
// レート制限ミドルウェア
func RateLimitMiddleware(requests int, window time.Duration) gin.HandlerFunc {
    limiter := rate.NewLimiter(rate.Every(window/time.Duration(requests)), requests)
    
    return func(c *gin.Context) {
        clientIP := c.ClientIP()
        
        // IP ベースのレート制限
        if !limiter.Allow() {
            c.JSON(http.StatusTooManyRequests, gin.H{
                "error": "rate limit exceeded",
                "retry_after": window.Seconds(),
            })
            c.Abort()
            return
        }
        
        c.Next()
    }
}
```

## 脆弱性対策

### SQL インジェクション対策
```go
// ✅ 安全: パラメータ化クエリ使用
func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
    var user User
    err := r.db.WithContext(ctx).Where("email = ?", email).First(&user).Error
    if err != nil {
        return nil, err
    }
    return &user, nil
}

// ❌ 危険: 文字列結合でSQL構築
func (r *UserRepository) FindByEmailUnsafe(ctx context.Context, email string) (*User, error) {
    query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)
    // SQL インジェクション脆弱性あり
}
```

### XSS 対策
```go
// HTML エスケープ
func (h *ResponseHelper) SafeHTML(content string) template.HTML {
    escaped := html.EscapeString(content)
    return template.HTML(escaped)
}

// CSP ヘッダー設定
func CSPMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        csp := "default-src 'self'; " +
               "script-src 'self' 'unsafe-inline' https://cdn.example.com; " +
               "style-src 'self' 'unsafe-inline'; " +
               "img-src 'self' data: https:; " +
               "connect-src 'self'; " +
               "font-src 'self'; " +
               "object-src 'none'; " +
               "frame-src 'none';"
        
        c.Header("Content-Security-Policy", csp)
        c.Next()
    }
}
```

### CSRF 対策
```go
// CSRF トークンミドルウェア
func CSRFMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        if c.Request.Method != "GET" && c.Request.Method != "HEAD" && c.Request.Method != "OPTIONS" {
            token := c.GetHeader("X-CSRF-Token")
            sessionToken := c.GetHeader("X-Session-Token")
            
            if !validateCSRFToken(token, sessionToken) {
                c.JSON(http.StatusForbidden, gin.H{"error": "invalid CSRF token"})
                c.Abort()
                return
            }
        }
        c.Next()
    }
}
```

### 入力検証
```go
// 入力検証構造体
type CreateUserRequest struct {
    Email    string `json:"email" validate:"required,email,max=255"`
    Password string `json:"password" validate:"required,min=8,max=128"`
    Name     string `json:"name" validate:"required,min=1,max=100"`
}

// バリデーションミドルウェア
func ValidationMiddleware(structType interface{}) gin.HandlerFunc {
    return func(c *gin.Context) {
        var request interface{}
        
        if err := c.ShouldBindJSON(&request); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": "invalid JSON"})
            c.Abort()
            return
        }
        
        validate := validator.New()
        if err := validate.Struct(request); err != nil {
            errors := make(map[string]string)
            for _, err := range err.(validator.ValidationErrors) {
                errors[err.Field()] = err.Tag()
            }
            c.JSON(http.StatusBadRequest, gin.H{"errors": errors})
            c.Abort()
            return
        }
        
        c.Set("validatedRequest", request)
        c.Next()
    }
}
```

## 監査・ログ

### セキュリティログ
```go
// セキュリティイベントログ
type SecurityEvent struct {
    Type        string    `json:"type"`
    UserID      string    `json:"user_id,omitempty"`
    IP          string    `json:"ip"`
    UserAgent   string    `json:"user_agent"`
    Resource    string    `json:"resource"`
    Action      string    `json:"action"`
    Success     bool      `json:"success"`
    Reason      string    `json:"reason,omitempty"`
    Timestamp   time.Time `json:"timestamp"`
}

func (l *SecurityLogger) LogAuthAttempt(userID, ip, userAgent string, success bool, reason string) {
    event := SecurityEvent{
        Type:      "authentication",
        UserID:    userID,
        IP:        ip,
        UserAgent: userAgent,
        Action:    "login",
        Success:   success,
        Reason:    reason,
        Timestamp: time.Now(),
    }
    
    l.writeEvent(event)
}

func (l *SecurityLogger) LogAccessAttempt(userID, ip, resource, action string, success bool) {
    event := SecurityEvent{
        Type:      "authorization",
        UserID:    userID,
        IP:        ip,
        Resource:  resource,
        Action:    action,
        Success:   success,
        Timestamp: time.Now(),
    }
    
    l.writeEvent(event)
}
```

### 監査トレイル
```sql
-- 監査テーブル
CREATE TABLE audit_schema.audit_trail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(255) NOT NULL,
    operation VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id UUID,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- 監査トリガー例
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_schema.audit_trail (table_name, operation, new_values, user_id, ip_address)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW), current_setting('app.current_user_id')::UUID, current_setting('app.client_ip')::INET);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_schema.audit_trail (table_name, operation, old_values, new_values, user_id, ip_address)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW), current_setting('app.current_user_id')::UUID, current_setting('app.client_ip')::INET);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_schema.audit_trail (table_name, operation, old_values, user_id, ip_address)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), current_setting('app.current_user_id')::UUID, current_setting('app.client_ip')::INET);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

## セキュリティテスト

### 脆弱性スキャン
```bash
# OWASP ZAP によるセキュリティスキャン
docker run -v $(pwd):/zap/wrk/:rw \
  owasp/zap2docker-stable zap-baseline.py \
  -t http://localhost:8001 \
  -g gen.conf \
  -r baseline_report.html

# Trivy による Docker イメージスキャン
trivy image auth-service:latest
```

### セキュリティテストケース
```go
// 認証バイパステスト
func TestAuthBypass(t *testing.T) {
    router := setupRouter()
    
    // JWT なしでアクセス
    req, _ := http.NewRequest("GET", "/api/v1/protected", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusUnauthorized, w.Code)
    
    // 無効な JWT でアクセス
    req.Header.Set("Authorization", "Bearer invalid_token")
    w = httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusUnauthorized, w.Code)
}

// SQL インジェクションテスト
func TestSQLInjection(t *testing.T) {
    // 悪意のあるペイロード
    maliciousEmail := "admin@example.com'; DROP TABLE users; --"
    
    // 正常に処理されることを確認（エラーではなく、見つからない結果）
    user, err := userRepo.FindByEmail(context.Background(), maliciousEmail)
    
    assert.NoError(t, err)
    assert.Nil(t, user)
    
    // テーブルが削除されていないことを確認
    count, err := userRepo.Count(context.Background())
    assert.NoError(t, err)
    assert.Greater(t, count, 0)
}
```

### ペネトレーションテスト
```bash
# Burp Suite のようなツールを使用したテスト項目
# 1. 認証バイパス
# 2. セッション管理の脆弱性
# 3. 入力検証の不備
# 4. 権限昇格
# 5. 情報漏洩
# 6. ビジネスロジックの脆弱性
```

## インシデント対応

### セキュリティインシデント対応手順
1. **検知・報告**: 異常なアクティビティの検知
2. **初期対応**: 影響範囲の特定、緊急対応
3. **封じ込め**: 攻撃の拡大防止
4. **根絶**: 脆弱性の修正
5. **復旧**: システムの正常化
6. **事後分析**: インシデントレポート作成

### 緊急連絡先
```yaml
Security Team:
  - Email: security@company.com
  - Phone: +81-XX-XXXX-XXXX
  - Slack: #security-incidents

Infrastructure Team:
  - Email: infra@company.com
  - Phone: +81-XX-XXXX-XXXX
  - Slack: #infrastructure

Management:
  - Email: management@company.com
  - Phone: +81-XX-XXXX-XXXX
```

---

**更新日**: 2025-08-17  
**バージョン**: 1.0.0