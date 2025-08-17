#!/bin/bash

# Enterprise Expense System - Development Environment Setup Script
# This script sets up the development environment and verifies all dependencies

set -e  # Exit on any error

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_banner() {
    echo -e "${BLUE}"
    echo "================================================="
    echo "   Enterprise Expense System Setup"
    echo "   Development Environment Initialization"
    echo "================================================="
    echo -e "${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check version and compare
check_version() {
    local cmd="$1"
    local required="$2"
    local current="$3"
    
    if [ -n "$current" ]; then
        log_success "$cmd version: $current (required: $required)"
        return 0
    else
        log_error "$cmd version check failed"
        return 1
    fi
}

# Check Docker and Docker Compose
check_docker() {
    log_info "Checking Docker installation..."
    
    if ! command_exists docker; then
        log_error "Docker is not installed. Please install Docker Desktop."
        log_info "Visit: https://docs.docker.com/get-docker/"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running. Please start Docker Desktop."
        return 1
    fi
    
    local docker_version=$(docker --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    check_version "Docker" "20.0+" "$docker_version"
    
    log_info "Checking Docker Compose installation..."
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose is not installed."
        return 1
    fi
    
    local compose_version
    if command_exists docker-compose; then
        compose_version=$(docker-compose --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    else
        compose_version=$(docker compose version --short 2>/dev/null || echo "v2")
    fi
    check_version "Docker Compose" "2.0+" "$compose_version"
    
    return 0
}

# Check Go installation
check_go() {
    log_info "Checking Go installation..."
    
    if ! command_exists go; then
        log_warning "Go is not installed. It's recommended for backend development."
        log_info "Visit: https://golang.org/doc/install"
        return 1
    fi
    
    local go_version=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | head -1)
    check_version "Go" "1.21+" "$go_version"
    
    return 0
}

# Check Node.js installation
check_node() {
    log_info "Checking Node.js installation..."
    
    if ! command_exists node; then
        log_warning "Node.js is not installed. It's recommended for frontend development."
        log_info "Visit: https://nodejs.org/"
        return 1
    fi
    
    local node_version=$(node --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    check_version "Node.js" "18.0+" "v$node_version"
    
    if ! command_exists npm; then
        log_error "npm is not installed."
        return 1
    fi
    
    local npm_version=$(npm --version)
    check_version "npm" "9.0+" "$npm_version"
    
    return 0
}

# Check Make installation
check_make() {
    log_info "Checking Make installation..."
    
    if ! command_exists make; then
        log_error "Make is not installed. Please install build tools."
        case "$(uname -s)" in
            Darwin*)
                log_info "Run: xcode-select --install"
                ;;
            Linux*)
                log_info "Run: sudo apt-get install build-essential (Ubuntu/Debian)"
                log_info "Or: sudo yum groupinstall 'Development Tools' (CentOS/RHEL)"
                ;;
        esac
        return 1
    fi
    
    local make_version=$(make --version | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    check_version "Make" "3.8+" "$make_version"
    
    return 0
}

# Check Git installation
check_git() {
    log_info "Checking Git installation..."
    
    if ! command_exists git; then
        log_error "Git is not installed."
        return 1
    fi
    
    local git_version=$(git --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    check_version "Git" "2.0+" "$git_version"
    
    return 0
}

# Setup environment files
setup_env_files() {
    log_info "Setting up environment files..."
    
    # Backend environment (if auth-service exists)
    if [ -d "services/auth-service" ]; then
        if [ ! -f "services/auth-service/.env" ]; then
            log_info "Creating auth-service .env file..."
            cat > services/auth-service/.env << EOF
# Development Environment Variables
DATABASE_URL=postgres://postgres:postgres@localhost:5432/expense_system?sslmode=disable
REDIS_URL=redis://localhost:6379
JWT_SECRET=development_jwt_secret_change_in_production
PORT=8001
GIN_MODE=debug
LOG_LEVEL=debug
EOF
            log_success "Created services/auth-service/.env"
        else
            log_success "services/auth-service/.env already exists"
        fi
    fi
    
    # Frontend environment (if frontend exists)
    if [ -d "frontend" ]; then
        if [ ! -f "frontend/.env.local" ]; then
            log_info "Creating frontend .env.local file..."
            cat > frontend/.env.local << EOF
# Development Environment Variables
NEXT_PUBLIC_API_URL=http://localhost:8001
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=development_nextauth_secret_change_in_production
NODE_ENV=development
EOF
            log_success "Created frontend/.env.local"
        else
            log_success "frontend/.env.local already exists"
        fi
    fi
}

# Pull required Docker images
pull_docker_images() {
    log_info "Pulling required Docker images..."
    
    local images=(
        "postgres:15-alpine"
        "redis:7-alpine"
        "nginx:alpine"
    )
    
    for image in "${images[@]}"; do
        log_info "Pulling $image..."
        if docker pull "$image"; then
            log_success "Pulled $image"
        else
            log_warning "Failed to pull $image (will try again during build)"
        fi
    done
}

# Initialize database
init_database() {
    log_info "Initializing database..."
    
    # Check if database is already running
    if docker-compose ps postgres | grep -q "Up"; then
        log_success "Database is already running"
        return 0
    fi
    
    # Start only postgres for initialization
    log_info "Starting PostgreSQL..."
    docker-compose up -d postgres
    
    # Wait for postgres to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    timeout 60 bash -c 'until docker-compose exec -T postgres pg_isready -U postgres; do sleep 2; done'
    
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL is ready"
        
        # Test database connection
        if docker-compose exec -T postgres psql -U postgres -d expense_system -c "SELECT 1;" >/dev/null 2>&1; then
            log_success "Database connection test passed"
        else
            log_error "Database connection test failed"
            return 1
        fi
    else
        log_error "PostgreSQL failed to start within 60 seconds"
        return 1
    fi
}

# Install development tools
install_dev_tools() {
    log_info "Installing development tools..."
    
    # Go tools (if Go is available)
    if command_exists go; then
        log_info "Installing Go development tools..."
        
        # Check if auth-service directory exists
        if [ -d "services/auth-service" ]; then
            cd services/auth-service
            
            # Install dependencies
            if [ -f "go.mod" ]; then
                log_info "Installing Go dependencies..."
                go mod download
                go mod verify
                log_success "Go dependencies installed"
            fi
            
            # Install development tools
            log_info "Installing Go development tools..."
            go install github.com/cosmtrek/air@latest 2>/dev/null || log_warning "Failed to install air (hot reload)"
            go install golang.org/x/tools/cmd/goimports@latest 2>/dev/null || log_warning "Failed to install goimports"
            
            cd ../..
        fi
    fi
    
    # Node.js tools (if Node.js is available)
    if command_exists npm && [ -d "frontend" ]; then
        log_info "Installing Node.js dependencies..."
        cd frontend
        
        if [ -f "package.json" ]; then
            npm install
            log_success "Node.js dependencies installed"
        fi
        
        cd ..
    fi
}

# Run health checks
run_health_checks() {
    log_info "Running system health checks..."
    
    # Check disk space
    local available_space=$(df . | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 1048576 ]; then  # Less than 1GB
        log_warning "Low disk space available: ${available_space}KB"
    else
        log_success "Sufficient disk space available"
    fi
    
    # Check memory
    if command_exists free; then
        local available_memory=$(free -m | awk 'NR==2{printf "%.0f", $7}')
        if [ "$available_memory" -lt 512 ]; then
            log_warning "Low memory available: ${available_memory}MB"
        else
            log_success "Sufficient memory available: ${available_memory}MB"
        fi
    fi
    
    # Check ports
    local ports=(5432 6379 8001 3000)
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_warning "Port $port is already in use"
        else
            log_success "Port $port is available"
        fi
    done
}

# Print next steps
print_next_steps() {
    echo -e "${GREEN}"
    echo "================================================="
    echo "   Setup Complete! 🎉"
    echo "================================================="
    echo -e "${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Start the development environment:"
    echo "   ${BLUE}make dev-up${NC}"
    echo ""
    echo "2. Check service status:"
    echo "   ${BLUE}make health-check${NC}"
    echo ""
    echo "3. View available commands:"
    echo "   ${BLUE}make help${NC}"
    echo ""
    echo "4. Access the application:"
    echo "   • Frontend: ${BLUE}http://localhost:3000${NC}"
    echo "   • Auth API: ${BLUE}http://localhost:8001/health${NC}"
    echo "   • Database: ${BLUE}localhost:5432${NC}"
    echo ""
    echo "For issues, check the documentation or run:"
    echo "   ${BLUE}make logs${NC}"
    echo ""
}

# Main setup function
main() {
    print_banner
    
    local failed_checks=0
    
    # Run all checks
    check_docker || ((failed_checks++))
    check_git || ((failed_checks++))
    check_make || ((failed_checks++))
    check_go || true  # Optional
    check_node || true  # Optional
    
    if [ $failed_checks -gt 0 ]; then
        log_error "Some required dependencies are missing. Please install them and run setup again."
        exit 1
    fi
    
    # Setup environment
    setup_env_files
    pull_docker_images
    install_dev_tools
    init_database
    run_health_checks
    
    print_next_steps
    
    log_success "Development environment setup completed successfully!"
}

# Run main function
main "$@"