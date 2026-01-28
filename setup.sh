#!/bin/bash
#
# Night Architecture - Setup Script
# Initializes the environment for legitimate multi-agent development
#

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   🦇  NIGHT ARCHITECTURE - SETUP                               ║"
echo "║                                                                ║"
echo "║   Legitimate multi-agent development system                    ║"
echo "║   Respecting Claude Max subscription boundaries                ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

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

# =============================================================================
# 1. CREATE DIRECTORY STRUCTURE
# =============================================================================

log_info "Creating directory structure..."

mkdir -p config
mkdir -p scripts
mkdir -p agents
mkdir -p workflows
mkdir -p patterns/{successes,failures,templates}
mkdir -p state/checkpoints
mkdir -p logs

log_success "Directory structure created"

# =============================================================================
# 2. CHECK DEPENDENCIES
# =============================================================================

log_info "Checking dependencies..."

# Check for required commands
MISSING_DEPS=()

if ! command -v curl &> /dev/null; then
    MISSING_DEPS+=("curl")
fi

if ! command -v jq &> /dev/null; then
    MISSING_DEPS+=("jq")
fi

if ! command -v yq &> /dev/null; then
    log_warn "yq not found - will use Python for YAML parsing"
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    log_error "Missing dependencies: ${MISSING_DEPS[*]}"
    log_info "Install with: sudo apt-get install ${MISSING_DEPS[*]}"
    exit 1
fi

log_success "Core dependencies OK"

# =============================================================================
# 3. CHECK CLAUDE CODE
# =============================================================================

log_info "Checking Claude Code installation..."

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    log_success "Claude Code found: $CLAUDE_VERSION"
else
    log_warn "Claude Code not found in PATH"
    log_info "Install from: https://docs.anthropic.com/en/docs/claude-code"
fi

# =============================================================================
# 4. INITIALIZE STATE
# =============================================================================

log_info "Initializing state..."

if [ ! -f state/session.json ]; then
    cat > state/session.json << 'EOF'
{
    "initialized_at": null,
    "last_active": null,
    "total_tasks_completed": 0,
    "total_claude_time_minutes": 0,
    "total_ollama_calls": 0,
    "total_api_calls": 0,
    "patterns_captured": 0,
    "current_session": null
}
EOF
    # Update initialized_at
    INIT_TIME=$(date -Iseconds)
    if command -v jq &> /dev/null; then
        jq --arg t "$INIT_TIME" '.initialized_at = $t' state/session.json > state/session.json.tmp
        mv state/session.json.tmp state/session.json
    fi
fi

log_success "State initialized"

# =============================================================================
# 5. MAKE SCRIPTS EXECUTABLE
# =============================================================================

log_info "Setting script permissions..."

chmod +x scripts/*.sh 2>/dev/null || true

log_success "Scripts are executable"

# =============================================================================
# 6. CHECK OLLAMA
# =============================================================================

log_info "Checking Ollama..."

OLLAMA_HOST="${OLLAMA_HOST:-localhost}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

if curl -s "http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
    log_success "Ollama is running at $OLLAMA_HOST:$OLLAMA_PORT"
    
    # Check for required model
    if curl -s "http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags" | grep -q "qwen3-coder"; then
        log_success "qwen3-coder model is available"
    else
        log_warn "qwen3-coder not found"
        log_info "Run: ollama pull qwen3-coder"
    fi
else
    log_warn "Ollama is not running"
    log_info "Start with: ollama serve"
    log_info "Or run: ./scripts/ollama-setup.sh"
fi

# =============================================================================
# 7. CREATE HELPER SCRIPT FOR OLLAMA
# =============================================================================

log_info "Creating Ollama setup script..."

cat > scripts/ollama-setup.sh << 'OLLAMA_SCRIPT'
#!/bin/bash
#
# Ollama Setup for Night Architecture (WSL with 5090)
#

set -e

echo "🦇 Night Architecture - Ollama Setup"
echo ""

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# WSL-specific: Bind to all interfaces
export OLLAMA_HOST=0.0.0.0:11434

# GPU settings for 5090
export OLLAMA_NUM_GPU=1
export OLLAMA_GPU_LAYERS=999

# Context window (64k for agent work)
export OLLAMA_NUM_CTX=65536

# Start Ollama if not running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Starting Ollama..."
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
fi

# Pull required models
echo "Pulling required models..."
ollama pull qwen3-coder

# Optional: Pull fallback model
# ollama pull deepseek-coder-v2

# Warmup
echo "Warming up model..."
curl -s http://localhost:11434/api/generate \
    -d '{"model":"qwen3-coder","prompt":"Ready for Night Architecture","stream":false}' \
    > /dev/null

echo ""
echo "✓ Ollama is ready!"
echo "  Host: localhost:11434"
echo "  Model: qwen3-coder"
echo ""

# Show GPU info if nvidia-smi is available
if command -v nvidia-smi &> /dev/null; then
    echo "GPU Status:"
    nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader
fi
OLLAMA_SCRIPT

chmod +x scripts/ollama-setup.sh
log_success "Ollama setup script created"

# =============================================================================
# 8. SUMMARY
# =============================================================================

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                    SETUP COMPLETE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Directory structure:"
echo "  ./config/      - Configuration files"
echo "  ./scripts/     - Utility scripts"
echo "  ./agents/      - Agent prompt definitions"
echo "  ./workflows/   - Workflow documentation"
echo "  ./patterns/    - Learned patterns storage"
echo "  ./state/       - Session state and checkpoints"
echo "  ./logs/        - Logs and metrics"
echo ""
echo "Next steps:"
echo "  1. Start Ollama:        ./scripts/ollama-setup.sh"
echo "  2. Check status:        ./scripts/tier-router.sh status"
echo "  3. Begin work with Claude Code"
echo ""
echo "Remember:"
echo "  • Claude Code (you) handles synthesis and critical decisions"
echo "  • Ollama handles parallel exploration and challenges"
echo "  • This respects your Claude Max subscription boundaries"
echo ""
echo "🦇 Night Architecture is ready!"
echo ""
