#!/bin/bash

# Enterprise Expense System - Integration Test Script
# This script runs comprehensive integration tests for all services

set -e  # Exit on any error

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_PROJECT_NAME="test-expense-system"
TEST_TIMEOUT=300  # 5 minutes
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_INTERVAL=2

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
    echo "   Enterprise Expense System"
    echo "   Integration Test Suite"
    echo "================================================="
    echo -e "${NC}"
}

# Cleanup function to ensure clean state
cleanup() {
    log_info "Cleaning up test environment..."
    
    # Stop and remove containers
    COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME docker-compose down -v --remove-orphans 2>/dev/null || true
    
    # Remove test networks
    docker network rm ${COMPOSE_PROJECT_NAME}_expense_network 2>/dev/null || true
    
    # Clean up test volumes
    docker volume rm ${COMPOSE_PROJECT_NAME}_postgres_data 2>/dev/null || true
    docker volume rm ${COMPOSE_PROJECT_NAME}_redis_data 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Start test environment
start_test_environment() {
    log_info "Starting test environment..."
    
    # Export environment variables for docker-compose
    export COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
    export DATABASE_URL="postgres://postgres:postgres@postgres:5432/expense_system_test"
    export REDIS_URL="redis://redis:6379"
    export JWT_SECRET="test_jwt_secret_for_integration_tests"
    
    # Start core services (postgres, redis)
    log_info "Starting core infrastructure services..."
    docker-compose up -d postgres redis
    
    # Wait for core services to be ready
    wait_for_service "postgres" "PostgreSQL" "docker-compose exec -T postgres pg_isready -U postgres"
    wait_for_service "redis" "Redis" "docker-compose exec -T redis redis-cli ping"
    
    return 0
}

# Wait for a service to be ready
wait_for_service() {
    local service_name="$1"
    local display_name="$2"
    local health_check_cmd="$3"
    
    log_info "Waiting for $display_name to be ready..."
    
    local retries=0
    while [ $retries -lt $HEALTH_CHECK_RETRIES ]; do
        if eval "$health_check_cmd" >/dev/null 2>&1; then
            log_success "$display_name is ready"
            return 0
        fi
        
        sleep $HEALTH_CHECK_INTERVAL
        ((retries++))
        
        if [ $((retries % 10)) -eq 0 ]; then
            log_info "Still waiting for $display_name... (${retries}/${HEALTH_CHECK_RETRIES})"
        fi
    done
    
    log_error "$display_name failed to become ready within $((HEALTH_CHECK_RETRIES * HEALTH_CHECK_INTERVAL)) seconds"
    return 1
}

# Test database connectivity and schema
test_database() {
    log_info "Testing database connectivity and schema..."
    
    # Test basic connectivity
    if docker-compose exec -T postgres psql -U postgres -d expense_system -c "SELECT 1;" >/dev/null 2>&1; then
        log_success "Database connectivity test passed"
    else
        log_error "Database connectivity test failed"
        return 1
    fi
    
    # Test schema existence
    local schemas=(auth_schema expense_schema workflow_schema audit_schema)
    for schema in "${schemas[@]}"; do
        if docker-compose exec -T postgres psql -U postgres -d expense_system -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '$schema';" | grep -q "$schema"; then
            log_success "Schema $schema exists"
        else
            log_error "Schema $schema does not exist"
            return 1
        fi
    done
    
    # Test initial data
    local user_count=$(docker-compose exec -T postgres psql -U postgres -d expense_system -t -c "SELECT COUNT(*) FROM auth_schema.users;" | tr -d ' ')
    if [ "$user_count" -gt 0 ]; then
        log_success "Initial user data exists ($user_count users)"
    else
        log_warning "No initial user data found"
    fi
    
    return 0
}

# Test Redis connectivity
test_redis() {
    log_info "Testing Redis connectivity..."
    
    # Test basic connectivity
    if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
        log_success "Redis connectivity test passed"
    else
        log_error "Redis connectivity test failed"
        return 1
    fi
    
    # Test write/read operations
    local test_key="integration_test_key"
    local test_value="integration_test_value"
    
    if docker-compose exec -T redis redis-cli set "$test_key" "$test_value" >/dev/null 2>&1; then
        log_success "Redis write test passed"
    else
        log_error "Redis write test failed"
        return 1
    fi
    
    local retrieved_value=$(docker-compose exec -T redis redis-cli get "$test_key" 2>/dev/null | tr -d '\r')
    if [ "$retrieved_value" = "$test_value" ]; then
        log_success "Redis read test passed"
    else
        log_error "Redis read test failed (expected: $test_value, got: $retrieved_value)"
        return 1
    fi
    
    # Cleanup test data
    docker-compose exec -T redis redis-cli del "$test_key" >/dev/null 2>&1
    
    return 0
}

# Test auth service (if available)
test_auth_service() {
    if [ ! -d "services/auth-service" ]; then
        log_warning "Auth service directory not found, skipping auth service tests"
        return 0
    fi
    
    log_info "Testing auth service..."
    
    # Build and start auth service
    log_info "Building auth service..."
    if docker-compose build auth-service; then
        log_success "Auth service build successful"
    else
        log_error "Auth service build failed"
        return 1
    fi
    
    log_info "Starting auth service..."
    docker-compose up -d auth-service
    
    # Wait for auth service to be ready
    wait_for_service "auth-service" "Auth Service" "curl -f http://localhost:8001/health"
    
    # Test health endpoint
    local health_response=$(curl -s http://localhost:8001/health 2>/dev/null || echo "")
    if echo "$health_response" | grep -q '"status":"ok"'; then
        log_success "Auth service health check passed"
    else
        log_error "Auth service health check failed"
        return 1
    fi
    
    # Test API v1 endpoint
    local api_response=$(curl -s http://localhost:8001/api/v1/ 2>/dev/null || echo "")
    if echo "$api_response" | grep -q '"message":"Auth Service API v1"'; then
        log_success "Auth service API v1 endpoint test passed"
    else
        log_error "Auth service API v1 endpoint test failed"
        return 1
    fi
    
    return 0
}

# Test frontend (if available)
test_frontend() {
    if [ ! -d "frontend" ]; then
        log_warning "Frontend directory not found, skipping frontend tests"
        return 0
    fi
    
    log_info "Testing frontend..."
    
    # Check if package.json exists
    if [ ! -f "frontend/package.json" ]; then
        log_warning "Frontend package.json not found, skipping frontend tests"
        return 0
    fi
    
    log_info "Building frontend..."
    if docker-compose build frontend; then
        log_success "Frontend build successful"
    else
        log_error "Frontend build failed"
        return 1
    fi
    
    log_info "Starting frontend..."
    docker-compose up -d frontend
    
    # Wait for frontend to be ready
    wait_for_service "frontend" "Frontend" "curl -f http://localhost:3000"
    
    # Test home page
    local home_response=$(curl -s http://localhost:3000 2>/dev/null || echo "")
    if echo "$home_response" | grep -q "Enterprise Expense System"; then
        log_success "Frontend home page test passed"
    else
        log_error "Frontend home page test failed"
        return 1
    fi
    
    return 0
}

# Run backend unit tests
test_backend_units() {
    if [ ! -d "services/auth-service" ]; then
        log_warning "Auth service directory not found, skipping backend unit tests"
        return 0
    fi
    
    log_info "Running backend unit tests..."
    
    # Check if Go is available
    if ! command -v go >/dev/null 2>&1; then
        log_warning "Go not found, skipping backend unit tests"
        return 0
    fi
    
    cd services/auth-service
    
    # Run tests with coverage
    if go test -v -race -coverprofile=coverage.out ./... 2>&1; then
        log_success "Backend unit tests passed"
        
        # Show coverage summary
        if [ -f coverage.out ]; then
            local coverage=$(go tool cover -func=coverage.out | tail -1 | awk '{print $3}')
            log_info "Test coverage: $coverage"
        fi
    else
        log_error "Backend unit tests failed"
        cd ../..
        return 1
    fi
    
    cd ../..
    return 0
}

# Run frontend unit tests
test_frontend_units() {
    if [ ! -d "frontend" ]; then
        log_warning "Frontend directory not found, skipping frontend unit tests"
        return 0
    fi
    
    log_info "Running frontend unit tests..."
    
    cd frontend
    
    # Check if npm is available and node_modules exists
    if ! command -v npm >/dev/null 2>&1; then
        log_warning "npm not found, skipping frontend unit tests"
        cd ..
        return 0
    fi
    
    if [ ! -d node_modules ]; then
        log_warning "node_modules not found, skipping frontend unit tests"
        cd ..
        return 0
    fi
    
    # Run tests
    if npm run test:ci 2>&1; then
        log_success "Frontend unit tests passed"
    else
        log_error "Frontend unit tests failed"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Performance test
test_performance() {
    log_info "Running basic performance tests..."
    
    # Test database query performance
    local start_time=$(date +%s%N)
    docker-compose exec -T postgres psql -U postgres -d expense_system -c "SELECT COUNT(*) FROM auth_schema.users;" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    
    if [ $duration -lt 1000 ]; then
        log_success "Database query performance test passed (${duration}ms)"
    else
        log_warning "Database query performance test slow (${duration}ms)"
    fi
    
    # Test Redis performance
    start_time=$(date +%s%N)
    docker-compose exec -T redis redis-cli set perf_test "test_value" >/dev/null 2>&1
    docker-compose exec -T redis redis-cli get perf_test >/dev/null 2>&1
    docker-compose exec -T redis redis-cli del perf_test >/dev/null 2>&1
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    if [ $duration -lt 100 ]; then
        log_success "Redis performance test passed (${duration}ms)"
    else
        log_warning "Redis performance test slow (${duration}ms)"
    fi
    
    return 0
}

# Generate test report
generate_test_report() {
    log_info "Generating test report..."
    
    local report_file="test-results/integration-test-report.txt"
    mkdir -p test-results
    
    {
        echo "Enterprise Expense System - Integration Test Report"
        echo "Generated at: $(date)"
        echo "=============================================="
        echo ""
        echo "Test Environment:"
        echo "- Docker: $(docker --version)"
        echo "- Docker Compose: $(docker-compose --version)"
        echo "- Project: $COMPOSE_PROJECT_NAME"
        echo ""
        echo "Services Status:"
        docker-compose ps
        echo ""
        echo "Container Logs Summary:"
        echo "----------------------"
        docker-compose logs --tail=10
    } > "$report_file"
    
    log_success "Test report generated: $report_file"
}

# Main test execution function
run_integration_tests() {
    local failed_tests=0
    
    # Database tests
    test_database || ((failed_tests++))
    
    # Redis tests
    test_redis || ((failed_tests++))
    
    # Unit tests
    test_backend_units || ((failed_tests++))
    test_frontend_units || ((failed_tests++))
    
    # Service tests
    test_auth_service || ((failed_tests++))
    test_frontend || ((failed_tests++))
    
    # Performance tests
    test_performance || true  # Non-critical
    
    return $failed_tests
}

# Main function
main() {
    print_banner
    
    # Check dependencies
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker not found. Please install Docker."
        exit 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose not found. Please install Docker Compose."
        exit 1
    fi
    
    # Start test environment
    start_test_environment
    
    # Run tests
    log_info "Starting integration test suite..."
    local start_time=$(date +%s)
    
    if run_integration_tests; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_success "All integration tests passed! (Duration: ${duration}s)"
        generate_test_report
        exit 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_error "Some integration tests failed. (Duration: ${duration}s)"
        generate_test_report
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --cleanup      Only run cleanup"
        echo "  --quick        Run quick tests only"
        echo ""
        echo "This script runs comprehensive integration tests for the"
        echo "Enterprise Expense System, including database, Redis,"
        echo "and service connectivity tests."
        exit 0
        ;;
    --cleanup)
        cleanup
        exit 0
        ;;
    --quick)
        log_info "Running quick integration tests..."
        start_test_environment
        test_database && test_redis
        exit $?
        ;;
    *)
        main "$@"
        ;;
esac