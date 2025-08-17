#!/bin/bash

# Enterprise Expense System - Build All Services Script
# This script builds all services and prepares them for deployment

set -e  # Exit on any error

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_TARGET="${BUILD_TARGET:-development}"
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1

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
    echo "   Build All Services"
    echo "   Target: $BUILD_TARGET"
    echo "================================================="
    echo -e "${NC}"
}

# Export Docker build environment variables
export DOCKER_BUILDKIT
export COMPOSE_DOCKER_CLI_BUILD

# Build auth service
build_auth_service() {
    if [ ! -d "services/auth-service" ]; then
        log_warning "Auth service directory not found, skipping..."
        return 0
    fi
    
    log_info "Building auth service..."
    
    # Build with Docker Compose
    if docker-compose build auth-service; then
        log_success "Auth service build completed"
        
        # Tag for different environments
        docker tag tatosato_keihi_auth-service:latest auth-service:$BUILD_TARGET
        docker tag tatosato_keihi_auth-service:latest auth-service:latest
        
        return 0
    else
        log_error "Auth service build failed"
        return 1
    fi
}

# Build BFF service (placeholder)
build_bff_service() {
    if [ ! -d "services/bff-service" ]; then
        log_warning "BFF service directory not found, skipping..."
        return 0
    fi
    
    log_info "Building BFF service..."
    
    # Placeholder for future BFF service build
    log_info "BFF service build not implemented yet"
    return 0
}

# Build frontend
build_frontend() {
    if [ ! -d "frontend" ]; then
        log_warning "Frontend directory not found, skipping..."
        return 0
    fi
    
    log_info "Building frontend..."
    
    # Build with Docker Compose
    if docker-compose build frontend; then
        log_success "Frontend build completed"
        
        # Tag for different environments
        docker tag tatosato_keihi_frontend:latest frontend:$BUILD_TARGET
        docker tag tatosato_keihi_frontend:latest frontend:latest
        
        return 0
    else
        log_error "Frontend build failed"
        return 1
    fi
}

# Build infrastructure images
build_infrastructure() {
    log_info "Pulling infrastructure images..."
    
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
            log_warning "Failed to pull $image"
        fi
    done
}

# Run tests before build (optional)
run_pre_build_tests() {
    if [ "$SKIP_TESTS" = "true" ]; then
        log_warning "Skipping pre-build tests (SKIP_TESTS=true)"
        return 0
    fi
    
    log_info "Running pre-build tests..."
    
    # Run auth service tests
    if [ -d "services/auth-service" ] && command -v go >/dev/null 2>&1; then
        log_info "Running auth service tests..."
        cd services/auth-service
        
        if go test -short ./...; then
            log_success "Auth service tests passed"
        else
            log_error "Auth service tests failed"
            cd ../..
            return 1
        fi
        
        cd ../..
    fi
    
    # Run frontend tests
    if [ -d "frontend" ] && command -v npm >/dev/null 2>&1; then
        log_info "Running frontend tests..."
        cd frontend
        
        if [ -f "package.json" ] && [ -d "node_modules" ]; then
            if npm run test:ci; then
                log_success "Frontend tests passed"
            else
                log_error "Frontend tests failed"
                cd ..
                return 1
            fi
        else
            log_warning "Frontend dependencies not installed, skipping tests"
        fi
        
        cd ..
    fi
    
    return 0
}

# Build all services
build_all_services() {
    local failed_builds=0
    
    # Run pre-build tests
    run_pre_build_tests || ((failed_builds++))
    
    # Build infrastructure
    build_infrastructure || ((failed_builds++))
    
    # Build services
    build_auth_service || ((failed_builds++))
    build_bff_service || ((failed_builds++))
    build_frontend || ((failed_builds++))
    
    return $failed_builds
}

# Show build summary
show_build_summary() {
    log_info "Build Summary:"
    echo ""
    
    # List built images
    echo "Built Images:"
    docker images | grep -E "(auth-service|frontend|bff-service)" | head -10
    echo ""
    
    # Show image sizes
    log_info "Image Sizes:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(auth-service|frontend|bff-service|postgres|redis)"
    echo ""
    
    # Show disk usage
    log_info "Docker Disk Usage:"
    docker system df
}

# Cleanup old images (optional)
cleanup_old_images() {
    if [ "$CLEANUP_OLD_IMAGES" = "true" ]; then
        log_info "Cleaning up old images..."
        
        # Remove dangling images
        docker image prune -f
        
        # Remove old tagged images (keep latest 3)
        for service in auth-service frontend bff-service; do
            old_images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" | grep "$service" | grep -v latest | tail -n +4 | awk '{print $3}')
            if [ -n "$old_images" ]; then
                echo "$old_images" | xargs docker rmi -f 2>/dev/null || true
            fi
        done
        
        log_success "Cleanup completed"
    fi
}

# Push images to registry (if configured)
push_images() {
    if [ -z "$DOCKER_REGISTRY" ]; then
        log_info "No registry configured, skipping image push"
        return 0
    fi
    
    log_info "Pushing images to registry: $DOCKER_REGISTRY"
    
    local services=(auth-service frontend)
    
    for service in "${services[@]}"; do
        if docker images | grep -q "$service"; then
            log_info "Pushing $service..."
            
            # Tag for registry
            docker tag "$service:$BUILD_TARGET" "$DOCKER_REGISTRY/$service:$BUILD_TARGET"
            docker tag "$service:latest" "$DOCKER_REGISTRY/$service:latest"
            
            # Push to registry
            if docker push "$DOCKER_REGISTRY/$service:$BUILD_TARGET" && docker push "$DOCKER_REGISTRY/$service:latest"; then
                log_success "Pushed $service to registry"
            else
                log_error "Failed to push $service to registry"
                return 1
            fi
        fi
    done
    
    return 0
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
    
    # Set build context
    log_info "Build configuration:"
    log_info "- Target: $BUILD_TARGET"
    log_info "- BuildKit: $DOCKER_BUILDKIT"
    log_info "- Registry: ${DOCKER_REGISTRY:-Not configured}"
    echo ""
    
    # Start build process
    local start_time=$(date +%s)
    
    if build_all_services; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        show_build_summary
        cleanup_old_images
        
        # Push to registry if configured
        if [ "$PUSH_TO_REGISTRY" = "true" ]; then
            push_images
        fi
        
        log_success "All builds completed successfully! (Duration: ${duration}s)"
        exit 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_error "Some builds failed. (Duration: ${duration}s)"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h              Show this help message"
        echo "  --production            Build for production"
        echo "  --development           Build for development (default)"
        echo "  --skip-tests            Skip pre-build tests"
        echo "  --cleanup               Clean up old images after build"
        echo "  --push                  Push images to registry after build"
        echo ""
        echo "Environment Variables:"
        echo "  BUILD_TARGET            Target environment (development|production)"
        echo "  DOCKER_REGISTRY         Docker registry URL for pushing images"
        echo "  SKIP_TESTS              Skip pre-build tests (true|false)"
        echo "  CLEANUP_OLD_IMAGES      Clean up old images (true|false)"
        echo "  PUSH_TO_REGISTRY        Push to registry after build (true|false)"
        echo ""
        exit 0
        ;;
    --production)
        export BUILD_TARGET="production"
        main
        ;;
    --development)
        export BUILD_TARGET="development"
        main
        ;;
    --skip-tests)
        export SKIP_TESTS="true"
        main
        ;;
    --cleanup)
        export CLEANUP_OLD_IMAGES="true"
        main
        ;;
    --push)
        export PUSH_TO_REGISTRY="true"
        main
        ;;
    *)
        main "$@"
        ;;
esac