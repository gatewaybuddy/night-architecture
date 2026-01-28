#!/bin/bash
#
# Night Architecture Docker Setup
# Initializes Docker environment with Ollama and supporting services
#

set -e

echo "🦇 Night Architecture - Docker Setup"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    echo "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

log_success "Docker is installed"

# Check if Docker is running
if ! docker info &> /dev/null; then
    log_error "Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

log_success "Docker is running"

# Check for NVIDIA GPU support (optional)
if command -v nvidia-smi &> /dev/null; then
    log_success "NVIDIA GPU detected"

    # Check for nvidia-container-toolkit
    if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
        log_success "NVIDIA Container Toolkit is configured"
    else
        log_warn "NVIDIA Container Toolkit not configured"
        log_info "GPU acceleration will not be available"
        log_info "Install with: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
    fi
else
    log_warn "No NVIDIA GPU detected - Ollama will run on CPU"
fi

# Create shared directory structure
log_info "Creating shared directories..."
mkdir -p shared/{input,output,patterns,logs}
log_success "Shared directories created"

# Start Docker Compose services
log_info "Starting Night Architecture services..."
docker compose up -d

# Wait for services to be healthy
log_info "Waiting for services to be ready..."
sleep 5

# Check Ollama
log_info "Checking Ollama status..."
if curl -s http://localhost:11434/api/tags &> /dev/null; then
    log_success "Ollama is running"
else
    log_warn "Ollama is starting (this may take a minute)..."
    sleep 10

    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        log_success "Ollama is now running"
    else
        log_error "Ollama failed to start"
        echo "Check logs with: docker compose logs ollama"
        exit 1
    fi
fi

# Pull required Ollama models
log_info "Pulling Ollama models (this may take several minutes)..."

log_info "Pulling qwen2.5-coder:7b (primary model)..."
docker exec night-arch-ollama ollama pull qwen2.5-coder:7b

log_info "Pulling deepseek-coder-v2:16b (fallback model)..."
docker exec night-arch-ollama ollama pull deepseek-coder-v2:16b

log_success "Models pulled successfully"

# Test Ollama with a simple prompt
log_info "Testing Ollama with sample prompt..."
TEST_RESPONSE=$(curl -s http://localhost:11434/api/generate \
    -d '{
        "model": "qwen2.5-coder:7b",
        "prompt": "Say \"Night Architecture is ready!\" and nothing else.",
        "stream": false
    }')

if echo "$TEST_RESPONSE" | grep -q "Night Architecture"; then
    log_success "Ollama test passed"
else
    log_warn "Ollama test inconclusive - check manually"
fi

# Check Redis
log_info "Checking Redis status..."
if docker exec night-arch-redis redis-cli ping &> /dev/null; then
    log_success "Redis is running"
else
    log_error "Redis failed to start"
    exit 1
fi

# Check PostgreSQL
log_info "Checking PostgreSQL status..."
if docker exec night-arch-postgres pg_isready -U nightarch &> /dev/null; then
    log_success "PostgreSQL is running"
else
    log_error "PostgreSQL failed to start"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "              NIGHT ARCHITECTURE - READY! 🦇"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Services running:"
echo "  • Ollama:     http://localhost:11434"
echo "  • Redis:      localhost:6380"
echo "  • PostgreSQL: localhost:5433"
echo ""
echo "Shared directory: ./shared/"
echo ""
echo "Next steps:"
echo "  1. Test Ollama: ./scripts/test-ollama.sh"
echo "  2. Run tier router: ./scripts/tier-router.sh explore \"Your question\""
echo "  3. Start session: ./scripts/session-manager.sh start \"project-name\""
echo ""
echo "Useful commands:"
echo "  • View logs:    docker compose logs -f [service]"
echo "  • Stop:         docker compose down"
echo "  • Restart:      docker compose restart [service]"
echo "  • Shell access: docker exec -it night-arch-ollama /bin/bash"
echo ""
