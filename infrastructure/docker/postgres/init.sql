-- Enterprise Expense System Database Initialization
-- This script sets up the initial database schema for microservices

-- Create schemas for microservice separation
CREATE SCHEMA IF NOT EXISTS auth_schema;
CREATE SCHEMA IF NOT EXISTS expense_schema;
CREATE SCHEMA IF NOT EXISTS workflow_schema;
CREATE SCHEMA IF NOT EXISTS audit_schema;

-- Set search path for initial setup
SET search_path TO auth_schema, public;

-- Users table for authentication service
CREATE TABLE IF NOT EXISTS auth_schema.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User sessions table for JWT refresh token management
CREATE TABLE IF NOT EXISTS auth_schema.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth_schema.users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE,
    ip_address INET,
    user_agent TEXT
);

-- User roles table for RBAC
CREATE TABLE IF NOT EXISTS auth_schema.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON auth_schema.users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON auth_schema.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON auth_schema.users(created_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON auth_schema.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_refresh_token ON auth_schema.user_sessions(refresh_token_hash);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON auth_schema.user_sessions(expires_at);

-- Insert default roles
INSERT INTO auth_schema.user_roles (name, description, permissions) VALUES
('admin', 'System Administrator', '{"users": ["create", "read", "update", "delete"], "expenses": ["create", "read", "update", "delete", "approve"], "workflows": ["create", "read", "update", "delete"], "reports": ["read", "export"]}'),
('manager', 'Department Manager', '{"expenses": ["read", "approve"], "reports": ["read"], "users": ["read"]}'),
('user', 'Regular User', '{"expenses": ["create", "read", "update"], "profile": ["read", "update"]}')
ON CONFLICT (name) DO NOTHING;

-- Insert development admin user (password: admin123)
-- Password hash for 'admin123' using bcrypt cost 12
INSERT INTO auth_schema.users (email, password_hash, role, first_name, last_name, is_active, is_verified) VALUES
('admin@example.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj5AJ9UqOgS6', 'admin', 'Admin', 'User', true, true),
('manager@example.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj5AJ9UqOgS6', 'manager', 'Manager', 'User', true, true),
('user@example.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj5AJ9UqOgS6', 'user', 'Regular', 'User', true, true)
ON CONFLICT (email) DO NOTHING;

-- Future schema preparations (empty for now, will be populated by respective services)

-- Expense schema placeholder
COMMENT ON SCHEMA expense_schema IS 'Schema for expense management microservice';

-- Workflow schema placeholder  
COMMENT ON SCHEMA workflow_schema IS 'Schema for workflow management microservice';

-- Audit schema placeholder
COMMENT ON SCHEMA audit_schema IS 'Schema for audit and event sourcing';

-- Grant permissions
GRANT USAGE ON SCHEMA auth_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth_schema TO postgres;

GRANT USAGE ON SCHEMA expense_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA expense_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA expense_schema TO postgres;

GRANT USAGE ON SCHEMA workflow_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA workflow_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA workflow_schema TO postgres;

GRANT USAGE ON SCHEMA audit_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit_schema TO postgres;

-- Reset search path
SET search_path TO public;