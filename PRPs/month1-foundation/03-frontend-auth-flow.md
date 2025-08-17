name: "03 Frontend Auth Flow - Next.js 14 Authentication & Layout"
description: |
  Next.js 14 App Routerを使用し、TypeScriptでタイプセーフな認証フローと
  レスポンシブなレイアウトコンポーネントを実装します。

## Goal
JWT認証と連携したNext.js 14フロントエンドを構築し、ユーザーエクスペリエンスに
優れた認証フロー、ダッシュボード、レスポンシブなレイアウトを実装する。

## Why
- Next.js 14 App Routerの実践的学習
- TypeScriptによる型安全な開発
- 現代的なReact状態管理（Zustand）の習得
- shadcn/ui + Tailwind CSSによるモダンUI開発
- JWT認証フローのフロントエンド実装パターン学習

## What
ログイン・ログアウト画面、認証状態管理、プロテクテッドルート、
ダッシュボード、ヘッダー・サイドバー・レイアウトコンポーネント、
レスポンシブデザイン、トークン管理、API統合

### Success Criteria
- [ ] Next.js 14 App Routerプロジェクトが正常に動作する
- [ ] JWT認証フロー（ログイン・ログアウト・トークンリフレッシュ）が完全に動作する
- [ ] プロテクテッドルートが適切に機能する
- [ ] レスポンシブなレイアウトコンポーネントが実装されている
- [ ] TypeScriptの型安全性が確保されている
- [ ] Zustandによる状態管理が適切に実装されている
- [ ] shadcn/ui コンポーネントが正しく統合されている
- [ ] Lighthouse Score 90以上を達成する

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Include these in your context window
- url: https://nextjs.org/docs/app
  why: Next.js 14 App Router patterns
  section: routing, layouts, loading, error handling

- url: https://ui.shadcn.com/docs
  why: shadcn/ui component patterns
  section: installation, theming, form components

- url: https://tailwindcss.com/docs
  why: Tailwind CSS utility classes
  section: responsive design, dark mode

- url: https://github.com/pmndrs/zustand
  why: Zustand state management patterns
  section: TypeScript usage, persistence

- url: https://nextjs.org/docs/app/building-your-application/authentication
  why: Next.js authentication patterns
  critical: middleware, protected routes

- url: https://react-hook-form.com/docs
  why: Form handling with validation
  section: TypeScript integration, error handling

- url: https://tanstack.com/query/latest
  why: API state management
  section: mutations, caching, error handling

- url: https://lucide.dev/
  why: Icon library integration
  section: React components, customization
```

### Current Codebase tree (after 02-backend-auth-service completion)
```bash
/Users/tatsuyasato/code/tatosato_keihi/
├── services/
│   └── auth-service/  # 完成した認証API
├── frontend/          # 基本構造のみ存在
│   ├── package.json
│   ├── next.config.js
│   └── src/
└── docker-compose.yml
```

### Desired Codebase tree with files to be added
```bash
frontend/
├── package.json                    # 依存関係管理
├── next.config.js                  # Next.js設定
├── tailwind.config.js              # Tailwind CSS設定
├── tsconfig.json                   # TypeScript設定
├── .eslintrc.json                  # ESLint設定
├── .env.local                      # 環境変数
├── src/
│   ├── app/                        # App Router
│   │   ├── layout.tsx              # Root layout
│   │   ├── page.tsx                # Home page
│   │   ├── loading.tsx             # Global loading UI
│   │   ├── error.tsx               # Global error UI
│   │   ├── not-found.tsx           # 404 page
│   │   ├── globals.css             # Global styles
│   │   ├── auth/
│   │   │   ├── login/
│   │   │   │   └── page.tsx        # Login page
│   │   │   └── layout.tsx          # Auth layout
│   │   ├── dashboard/
│   │   │   ├── page.tsx            # Dashboard page
│   │   │   ├── layout.tsx          # Dashboard layout
│   │   │   └── settings/
│   │   │       └── page.tsx        # Settings page
│   │   └── api/
│   │       └── auth/
│   │           └── refresh/
│   │               └── route.ts    # Token refresh API route
│   ├── components/
│   │   ├── ui/                     # shadcn/ui components
│   │   │   ├── button.tsx
│   │   │   ├── input.tsx
│   │   │   ├── form.tsx
│   │   │   ├── toast.tsx
│   │   │   ├── avatar.tsx
│   │   │   ├── dropdown-menu.tsx
│   │   │   ├── sidebar.tsx
│   │   │   └── navigation-menu.tsx
│   │   ├── layout/
│   │   │   ├── header.tsx          # Header component
│   │   │   ├── sidebar.tsx         # Sidebar component
│   │   │   ├── footer.tsx          # Footer component
│   │   │   └── navigation.tsx      # Navigation component
│   │   ├── auth/
│   │   │   ├── login-form.tsx      # Login form component
│   │   │   ├── logout-button.tsx   # Logout button
│   │   │   └── auth-guard.tsx      # Protected route wrapper
│   │   ├── dashboard/
│   │   │   ├── stats-card.tsx      # Statistics card
│   │   │   ├── recent-activity.tsx # Recent activity
│   │   │   └── quick-actions.tsx   # Quick action buttons
│   │   └── common/
│   │       ├── loading-spinner.tsx # Loading component
│   │       ├── error-boundary.tsx  # Error boundary
│   │       └── theme-toggle.tsx    # Dark mode toggle
│   ├── lib/
│   │   ├── api.ts                  # API client configuration
│   │   ├── auth.ts                 # Authentication utilities
│   │   ├── utils.ts                # Utility functions
│   │   ├── validations.ts          # Form validation schemas
│   │   └── constants.ts            # Application constants
│   ├── hooks/
│   │   ├── use-auth.ts             # Authentication hook
│   │   ├── use-api.ts              # API integration hook
│   │   └── use-local-storage.ts    # Local storage hook
│   ├── store/
│   │   ├── auth-store.ts           # Zustand auth store
│   │   ├── ui-store.ts             # UI state store
│   │   └── index.ts                # Store exports
│   ├── types/
│   │   ├── auth.ts                 # Authentication types
│   │   ├── user.ts                 # User types
│   │   ├── api.ts                  # API response types
│   │   └── index.ts                # Type exports
│   └── middleware.ts               # Next.js middleware for auth
├── components.json                 # shadcn/ui configuration
├── Dockerfile                      # Frontend container
└── .dockerignore                   # Docker ignore file
```

### Known Gotchas of our codebase & Library Quirks
```typescript
// CRITICAL: Next.js 14 App Router specifics
// Server Components are default, Client Components need 'use client'
// Layouts persist across navigation, pages re-render

// CRITICAL: Zustand persistence
// Hydration mismatch issues with SSR
// Need proper client-side initialization

// CRITICAL: shadcn/ui setup
// Requires specific Tailwind CSS configuration
// Component customization through CSS variables

// CRITICAL: Middleware execution
// Runs on all requests, needs careful performance consideration
// Cannot access localStorage/sessionStorage in middleware

// CRITICAL: TypeScript strict mode
// Next.js requires strict TypeScript configuration
// API response types must match backend exactly

// CRITICAL: JWT token storage
// HttpOnly cookies vs localStorage trade-offs
// CSRF protection considerations

// CRITICAL: API route handlers
// New App Router API routes syntax
// Proper error handling and type safety
```

## Implementation Blueprint

### Authentication State Management Architecture
Zustand + TypeScript による型安全な状態管理

```typescript
// store/auth-store.ts
interface AuthState {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (credentials: LoginCredentials) => Promise<void>
  logout: () => void
  refreshToken: () => Promise<void>
  checkAuth: () => Promise<void>
}

// PATTERN: Zustand with persistence and TypeScript
const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      isAuthenticated: false,
      isLoading: true,
      // ... implementation
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ user: state.user, isAuthenticated: state.isAuthenticated }),
    }
  )
)
```

### App Router Structure with Authentication
Next.js 14 の最新パターンによる実装

```typescript
// middleware.ts - Route protection
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // PATTERN: JWT verification in middleware
  const token = request.cookies.get('access_token')?.value
  
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/auth/login', request.url))
  }
  
  return NextResponse.next()
}
```

### Tasks to be completed in order

```yaml
Task 1: Next.js 14プロジェクト設定
MODIFY frontend/package.json:
  - ADD dependencies: next@14, react@18, typescript
  - ADD dev dependencies: @types/react, eslint-config-next
  - ADD shadcn/ui and Tailwind CSS dependencies
  - ADD Zustand and React Hook Form

CONFIGURE tsconfig.json:
  - ENABLE strict mode
  - CONFIGURE path aliases (@/ for src/)
  - SET proper module resolution

SETUP tailwind.config.js:
  - CONFIGURE shadcn/ui integration
  - ADD custom design tokens
  - SETUP dark mode support

Task 2: shadcn/ui コンポーネント統合
INITIALIZE shadcn/ui:
  - RUN shadcn-ui init
  - CONFIGURE components.json
  - ADD base UI components (button, input, form, toast)

INSTALL core components:
  - ADD Button, Input, Form components
  - ADD Toast notification system
  - ADD Avatar, Dropdown Menu components
  - ADD Navigation Menu, Sidebar components

Task 3: 認証状態管理実装
CREATE store/auth-store.ts:
  - IMPLEMENT Zustand store with TypeScript
  - ADD authentication state management
  - IMPLEMENT login, logout, refresh methods
  - CONFIGURE persistence with localStorage

CREATE types/auth.ts:
  - DEFINE User interface
  - DEFINE LoginCredentials interface
  - DEFINE AuthResponse interface
  - EXPORT all authentication types

CREATE lib/auth.ts:
  - IMPLEMENT JWT token utilities
  - ADD token validation functions
  - IMPLEMENT API client setup
  - ADD error handling utilities

Task 4: API統合実装
CREATE lib/api.ts:
  - SETUP axios instance with interceptors
  - IMPLEMENT automatic token attachment
  - ADD response/error interceptors
  - CONFIGURE base URL and timeout

CREATE hooks/use-auth.ts:
  - IMPLEMENT authentication hook
  - WRAP Zustand store with React hook
  - ADD loading states and error handling
  - PROVIDE convenient auth methods

CREATE app/api/auth/refresh/route.ts:
  - IMPLEMENT token refresh API route
  - HANDLE token refresh logic
  - SET HttpOnly cookies for security
  - PROVIDE proper error responses

Task 5: 認証画面実装
CREATE app/auth/login/page.tsx:
  - IMPLEMENT login page with form
  - USE React Hook Form for validation
  - INTEGRATE with auth store
  - ADD loading states and error display

CREATE components/auth/login-form.tsx:
  - IMPLEMENT reusable login form
  - ADD form validation with zod
  - PROVIDE accessible form components
  - HANDLE submission and errors

CREATE components/auth/auth-guard.tsx:
  - IMPLEMENT protected route wrapper
  - CHECK authentication status
  - REDIRECT to login if not authenticated
  - SHOW loading state during check

Task 6: レイアウトコンポーネント実装
CREATE components/layout/header.tsx:
  - IMPLEMENT responsive header
  - ADD navigation menu
  - INCLUDE user profile dropdown
  - ADD logout functionality

CREATE components/layout/sidebar.tsx:
  - IMPLEMENT collapsible sidebar
  - ADD navigation links
  - SUPPORT mobile responsiveness
  - INTEGRATE with navigation state

CREATE app/layout.tsx:
  - IMPLEMENT root layout
  - CONFIGURE providers (auth, toast)
  - ADD global styles and fonts
  - SETUP metadata and viewport

Task 7: ダッシュボード実装
CREATE app/dashboard/page.tsx:
  - IMPLEMENT dashboard landing page
  - ADD statistics cards
  - SHOW recent activity
  - PROVIDE quick action buttons

CREATE app/dashboard/layout.tsx:
  - IMPLEMENT dashboard layout
  - INTEGRATE header and sidebar
  - ADD protected route wrapper
  - CONFIGURE responsive design

CREATE components/dashboard/:
  - IMPLEMENT StatsCard component
  - CREATE RecentActivity component
  - ADD QuickActions component
  - ENSURE responsive design

Task 8: ミドルウェア・保護実装
CREATE middleware.ts:
  - IMPLEMENT route protection
  - CHECK authentication status
  - REDIRECT unauthorized users
  - HANDLE token validation

CREATE hooks/use-api.ts:
  - IMPLEMENT API integration hook
  - USE React Query/SWR for caching
  - HANDLE loading and error states
  - PROVIDE retry mechanisms
```

### Task Details with Pseudocode

#### Task 2: shadcn/ui セットアップ
```bash
# shadcn/ui initialization
npx shadcn-ui@latest init

# Core component installation
npx shadcn-ui@latest add button
npx shadcn-ui@latest add input
npx shadcn-ui@latest add form
npx shadcn-ui@latest add toast
npx shadcn-ui@latest add avatar
npx shadcn-ui@latest add dropdown-menu
```

#### Task 3: 認証状態管理
```typescript
// store/auth-store.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (credentials: LoginCredentials) => Promise<void>
  logout: () => void
  refreshToken: () => Promise<void>
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      isAuthenticated: false,
      isLoading: false,
      
      login: async (credentials: LoginCredentials) => {
        set({ isLoading: true })
        try {
          // CRITICAL: API call to backend auth service
          const response = await api.post('/auth/login', credentials)
          const { user, access_token, refresh_token } = response.data
          
          // PATTERN: Store tokens securely
          document.cookie = `access_token=${access_token}; httpOnly; secure; samesite=strict`
          document.cookie = `refresh_token=${refresh_token}; httpOnly; secure; samesite=strict`
          
          set({ user, isAuthenticated: true, isLoading: false })
        } catch (error) {
          set({ isLoading: false })
          throw error
        }
      },
      
      logout: () => {
        // PATTERN: Clear auth state and tokens
        document.cookie = 'access_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;'
        document.cookie = 'refresh_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;'
        set({ user: null, isAuthenticated: false })
      }
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ 
        user: state.user, 
        isAuthenticated: state.isAuthenticated 
      }),
    }
  )
)
```

#### Task 5: ログインフォーム実装
```typescript
// components/auth/login-form.tsx
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

type LoginFormData = z.infer<typeof loginSchema>

export function LoginForm() {
  const { login, isLoading } = useAuthStore()
  
  const form = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  })
  
  const onSubmit = async (data: LoginFormData) => {
    try {
      await login(data)
      // PATTERN: Redirect after successful login
      router.push('/dashboard')
    } catch (error) {
      // PATTERN: Show error toast
      toast({
        title: 'Login failed',
        description: error.message,
        variant: 'destructive',
      })
    }
  }
  
  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input placeholder="Enter your email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        {/* Password field similar pattern */}
        <Button type="submit" className="w-full" disabled={isLoading}>
          {isLoading ? 'Signing in...' : 'Sign in'}
        </Button>
      </form>
    </Form>
  )
}
```

#### Task 6: レスポンシブヘッダー
```typescript
// components/layout/header.tsx
'use client'

import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'

export function Header() {
  const { user, logout } = useAuthStore()
  
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-14 items-center">
        {/* PATTERN: Responsive navigation */}
        <div className="mr-4 hidden md:flex">
          <nav className="flex items-center space-x-6 text-sm font-medium">
            <Link href="/dashboard">Dashboard</Link>
            <Link href="/expenses">Expenses</Link>
            <Link href="/reports">Reports</Link>
          </nav>
        </div>
        
        {/* PATTERN: Mobile menu button */}
        <Button variant="ghost" className="mr-2 px-0 text-base hover:bg-transparent focus-visible:bg-transparent focus-visible:ring-0 focus-visible:ring-offset-0 md:hidden">
          <Menu className="h-6 w-6" />
        </Button>
        
        <div className="flex flex-1 items-center justify-between space-x-2 md:justify-end">
          {/* PATTERN: User profile dropdown */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="relative h-8 w-8 rounded-full">
                <Avatar className="h-8 w-8">
                  <AvatarImage src={user?.avatar} alt={user?.name} />
                  <AvatarFallback>{user?.name?.charAt(0)}</AvatarFallback>
                </Avatar>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="w-56" align="end" forceMount>
              <DropdownMenuItem onClick={() => router.push('/dashboard/settings')}>
                Settings
              </DropdownMenuItem>
              <DropdownMenuItem onClick={logout}>
                Log out
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  )
}
```

### Integration Points
```yaml
BACKEND_API:
  - base_url: http://localhost:8001
  - authentication: Bearer token in Authorization header
  - endpoints: /auth/login, /auth/refresh, /auth/logout, /users/me

STATE_MANAGEMENT:
  - authentication: Zustand store with persistence
  - ui_state: Sidebar collapse, theme, notifications
  - api_cache: React Query for server state

ROUTING:
  - protected_routes: /dashboard, /expenses, /reports
  - public_routes: /, /auth/login
  - middleware: Token validation and redirect logic

STYLING:
  - framework: Tailwind CSS with custom design system
  - components: shadcn/ui for consistent UI
  - responsive: Mobile-first approach
  - dark_mode: System preference with manual toggle
```

## Validation Loop

### Level 1: TypeScript & Linting
```bash
# TypeScript type checking
npm run type-check

# ESLint linting
npm run lint

# Expected: No TypeScript errors, no linting errors
# If failing: Fix type errors and linting issues
```

### Level 2: Component Testing
```bash
# Component unit tests
npm run test

# Expected: All component tests pass
# If failing: Fix component logic and test cases
```

### Level 3: Authentication Flow Testing
```bash
# Start development server
npm run dev

# Test login flow
# 1. Navigate to http://localhost:3000/auth/login
# 2. Enter valid credentials
# 3. Verify redirect to dashboard
# 4. Verify protected routes work with valid token
# 5. Test logout functionality

# Expected: Complete auth flow works without errors
# If failing: Check API integration and state management
```

### Level 4: Responsive Design Testing
```bash
# Lighthouse audit
npm run lighthouse

# Manual responsive testing
# 1. Test on mobile (375px width)
# 2. Test on tablet (768px width)
# 3. Test on desktop (1024px+ width)
# 4. Verify navigation and layout work on all sizes

# Expected: Lighthouse score 90+, responsive design works
# If failing: Optimize performance and fix responsive issues
```

## Final validation Checklist
- [ ] Next.js 14アプリ起動成功: `npm run dev`
- [ ] TypeScriptエラー0件: `npm run type-check`
- [ ] Linting成功: `npm run lint`
- [ ] 認証フロー完全動作: ログイン → ダッシュボード → ログアウト
- [ ] プロテクテッドルート動作: 未認証時のリダイレクト確認
- [ ] レスポンシブデザイン: モバイル・タブレット・デスクトップ対応
- [ ] Lighthouse Score 90以上: パフォーマンス・アクセシビリティ
- [ ] shadcn/ui統合完了: 全UIコンポーネント動作

---

## Anti-Patterns to Avoid
- ❌ Client Componentで不要な'use client'ディレクティブ
- ❌ サーバーサイドでlocalStorageアクセス
- ❌ 認証トークンをlocalStorageに平文保存
- ❌ useEffectでの無限再レンダリング
- ❌ 型定義なしのAPI呼び出し
- ❌ レスポンシブデザインの考慮不足
- ❌ アクセシビリティ対応の忘れ

**信頼度レベル: 8/10**
- Next.js 14、shadcn/ui、Zustandの確立されたパターン使用
- TypeScriptによる型安全性確保
- 段階的実装とテストによる品質確保
- App Routerの新機能による学習コスト増加あり