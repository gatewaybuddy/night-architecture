#!/bin/bash
#
# Night Architecture - Tier Router
# Routes inference requests to the appropriate tier:
#   1. Claude Max (via Claude Code) - Primary, for synthesis
#   2. Ollama Local - Secondary, for parallel/bulk work
#   3. API - Emergency only
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-localhost}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3-coder}"

STATE_FILE="$PROJECT_DIR/state/session.json"
LOG_FILE="$PROJECT_DIR/logs/tier-router.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        INFO)    echo -e "${BLUE}ℹ${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}✓${NC} $message" ;;
        WARN)    echo -e "${YELLOW}⚠${NC} $message" ;;
        ERROR)   echo -e "${RED}✗${NC} $message" ;;
        TIER)    echo -e "${PURPLE}◆${NC} $message" ;;
    esac
}

# =============================================================================
# OLLAMA FUNCTIONS
# =============================================================================

check_ollama() {
    curl -s "http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags" > /dev/null 2>&1
}

call_ollama() {
    local prompt=$1
    local system_prompt="${2:-}"
    local temperature="${3:-0.5}"
    
    local payload
    if [ -n "$system_prompt" ]; then
        payload=$(jq -n \
            --arg model "$OLLAMA_MODEL" \
            --arg prompt "$prompt" \
            --arg system "$system_prompt" \
            --argjson temp "$temperature" \
            '{model: $model, prompt: $prompt, system: $system, temperature: $temp, stream: false}')
    else
        payload=$(jq -n \
            --arg model "$OLLAMA_MODEL" \
            --arg prompt "$prompt" \
            --argjson temp "$temperature" \
            '{model: $model, prompt: $prompt, temperature: $temp, stream: false}')
    fi
    
    local response
    response=$(curl -s "http://$OLLAMA_HOST:$OLLAMA_PORT/api/generate" \
        -d "$payload" \
        --max-time 300)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        echo "$response" | jq -r '.response // empty'
        
        # Update stats
        if [ -f "$STATE_FILE" ]; then
            jq '.total_ollama_calls += 1' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        fi
        
        return 0
    else
        return 1
    fi
}

# =============================================================================
# AGENT CALLERS
# =============================================================================

load_agent_prompt() {
    local agent_name=$1
    local config_file="$PROJECT_DIR/config/agents.yaml"
    
    # Extract system prompt using Python (yq might not be available)
    python3 << EOF
import yaml
import sys

with open('$config_file', 'r') as f:
    config = yaml.safe_load(f)

agents = config.get('agents', {})
agent = agents.get('$agent_name', {})
print(agent.get('system_prompt', ''))
EOF
}

call_agent() {
    local agent_name=$1
    local user_prompt=$2
    
    log TIER "Calling Ollama agent: $agent_name"
    
    local system_prompt
    system_prompt=$(load_agent_prompt "$agent_name")
    
    if [ -z "$system_prompt" ]; then
        log ERROR "Agent not found: $agent_name"
        return 1
    fi
    
    call_ollama "$user_prompt" "$system_prompt"
}

# =============================================================================
# EXPLORATION (Multiple Perspectives)
# =============================================================================

run_exploration() {
    local topic=$1
    local output_dir="${2:-$PROJECT_DIR/state/exploration_$(date +%s)}"
    
    mkdir -p "$output_dir"
    
    log INFO "Running parallel exploration on: ${topic:0:50}..."
    
    # Run explorers in parallel
    local pids=()
    
    # Conservative Explorer
    (
        log TIER "Conservative Explorer starting..."
        call_agent "explorer_conservative" "$topic" > "$output_dir/conservative.md" 2>/dev/null
        log SUCCESS "Conservative Explorer complete"
    ) &
    pids+=($!)
    
    # Aggressive Explorer
    (
        log TIER "Aggressive Explorer starting..."
        call_agent "explorer_aggressive" "$topic" > "$output_dir/aggressive.md" 2>/dev/null
        log SUCCESS "Aggressive Explorer complete"
    ) &
    pids+=($!)
    
    # Alternative Explorer
    (
        log TIER "Alternative Explorer starting..."
        call_agent "explorer_alternative" "$topic" > "$output_dir/alternative.md" 2>/dev/null
        log SUCCESS "Alternative Explorer complete"
    ) &
    pids+=($!)
    
    # Wait for all
    for pid in "${pids[@]}"; do
        wait $pid 2>/dev/null || true
    done
    
    log SUCCESS "Exploration complete. Results in: $output_dir"
    
    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                    EXPLORATION RESULTS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    for perspective in conservative aggressive alternative; do
        if [ -f "$output_dir/$perspective.md" ]; then
            echo -e "${CYAN}=== ${perspective^^} ===${NC}"
            head -30 "$output_dir/$perspective.md"
            echo ""
            echo "[...see $output_dir/$perspective.md for full output]"
            echo ""
        fi
    done
    
    echo "════════════════════════════════════════════════════════════════"
    echo "Now synthesize these perspectives into YOUR decision."
    echo "════════════════════════════════════════════════════════════════"
}

# =============================================================================
# DEVIL'S ADVOCATE CHALLENGE
# =============================================================================

run_challenge() {
    local proposal=$1
    
    log INFO "Running Devil's Advocate challenge..."
    log TIER "Devil's Advocate analyzing proposal..."
    
    local result
    result=$(call_agent "devils_advocate" "Analyze and challenge this proposal:\n\n$proposal")
    
    if [ -n "$result" ]; then
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "                    DEVIL'S ADVOCATE CHALLENGE"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "$result"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "Address these concerns or acknowledge why you're proceeding anyway."
        echo "════════════════════════════════════════════════════════════════"
    else
        log ERROR "Devil's Advocate failed to respond"
        return 1
    fi
}

# =============================================================================
# CODE REVIEW
# =============================================================================

run_review() {
    local code_file=$1
    local output_dir="${2:-$PROJECT_DIR/state/review_$(date +%s)}"
    
    mkdir -p "$output_dir"
    
    if [ ! -f "$code_file" ]; then
        log ERROR "File not found: $code_file"
        return 1
    fi
    
    local code
    code=$(cat "$code_file")
    
    log INFO "Running code review on: $code_file"
    
    # Run reviewers in parallel
    local pids=()
    
    # Security Review
    (
        log TIER "Security Reviewer starting..."
        call_agent "reviewer_security" "Review this code for security issues:\n\n$code" > "$output_dir/security.md" 2>/dev/null
        log SUCCESS "Security Review complete"
    ) &
    pids+=($!)
    
    # Performance Review
    (
        log TIER "Performance Reviewer starting..."
        call_agent "reviewer_performance" "Review this code for performance issues:\n\n$code" > "$output_dir/performance.md" 2>/dev/null
        log SUCCESS "Performance Review complete"
    ) &
    pids+=($!)
    
    # Maintainability Review
    (
        log TIER "Maintainability Reviewer starting..."
        call_agent "reviewer_maintainability" "Review this code for maintainability:\n\n$code" > "$output_dir/maintainability.md" 2>/dev/null
        log SUCCESS "Maintainability Review complete"
    ) &
    pids+=($!)
    
    # Wait for all
    for pid in "${pids[@]}"; do
        wait $pid 2>/dev/null || true
    done
    
    log SUCCESS "Review complete. Results in: $output_dir"
    
    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                    CODE REVIEW RESULTS"
    echo "════════════════════════════════════════════════════════════════"
    
    for review_type in security performance maintainability; do
        if [ -f "$output_dir/$review_type.md" ]; then
            echo ""
            echo -e "${CYAN}=== ${review_type^^} ===${NC}"
            cat "$output_dir/$review_type.md"
        fi
    done
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
}

# =============================================================================
# PATTERN MANAGEMENT
# =============================================================================

capture_pattern() {
    local pattern_type=$1  # success or failure
    local task_desc=$2
    local details=$3
    
    local timestamp=$(date -Iseconds)
    local pattern_id=$(echo "$task_desc$timestamp" | md5sum | cut -c1-8)
    local pattern_file="$PROJECT_DIR/patterns/${pattern_type}s/${pattern_id}.json"
    
    case $pattern_type in
        success)
            jq -n \
                --arg task "$task_desc" \
                --arg approach "$details" \
                --arg ts "$timestamp" \
                '{task: $task, approach: $approach, timestamp: $ts}' > "$pattern_file"
            ;;
        failure)
            jq -n \
                --arg task "$task_desc" \
                --arg issue "$details" \
                --arg ts "$timestamp" \
                '{task: $task, issue: $issue, timestamp: $ts}' > "$pattern_file"
            ;;
    esac
    
    log SUCCESS "Pattern captured: $pattern_file"
    
    # Update stats
    if [ -f "$STATE_FILE" ]; then
        jq '.patterns_captured += 1' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
}

search_patterns() {
    local query=$1
    
    log INFO "Searching patterns for: $query"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                    RELEVANT PATTERNS"
    echo "════════════════════════════════════════════════════════════════"
    
    echo ""
    echo -e "${GREEN}=== SUCCESSES ===${NC}"
    grep -l -i "$query" "$PROJECT_DIR/patterns/successes/"*.json 2>/dev/null | while read -r file; do
        cat "$file" | jq -r '"• \(.task): \(.approach)"'
    done || echo "No matching success patterns"
    
    echo ""
    echo -e "${RED}=== FAILURES (Learn from these!) ===${NC}"
    grep -l -i "$query" "$PROJECT_DIR/patterns/failures/"*.json 2>/dev/null | while read -r file; do
        cat "$file" | jq -r '"• \(.task): \(.issue)"'
    done || echo "No matching failure patterns"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
}

# =============================================================================
# STATUS
# =============================================================================

show_status() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           NIGHT ARCHITECTURE - STATUS                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Ollama Status
    echo -e "${CYAN}Tier 2: Ollama Local${NC}"
    if check_ollama; then
        echo -e "  Status: ${GREEN}Available${NC}"
        echo "  Host: $OLLAMA_HOST:$OLLAMA_PORT"
        echo "  Model: $OLLAMA_MODEL"
        
        # Show available models
        echo "  Available models:"
        curl -s "http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags" | jq -r '.models[].name' | while read -r model; do
            echo "    - $model"
        done
    else
        echo -e "  Status: ${RED}Offline${NC}"
        echo "  Run: ./scripts/ollama-setup.sh"
    fi
    echo ""
    
    # Session Stats
    if [ -f "$STATE_FILE" ]; then
        echo -e "${CYAN}Session Statistics${NC}"
        echo "  Tasks completed: $(jq -r '.total_tasks_completed' "$STATE_FILE")"
        echo "  Ollama calls: $(jq -r '.total_ollama_calls' "$STATE_FILE")"
        echo "  API calls: $(jq -r '.total_api_calls' "$STATE_FILE")"
        echo "  Patterns captured: $(jq -r '.patterns_captured' "$STATE_FILE")"
        echo ""
    fi
    
    # Pattern counts
    echo -e "${CYAN}Pattern Bank${NC}"
    local success_count=$(ls -1 "$PROJECT_DIR/patterns/successes/"*.json 2>/dev/null | wc -l || echo "0")
    local failure_count=$(ls -1 "$PROJECT_DIR/patterns/failures/"*.json 2>/dev/null | wc -l || echo "0")
    echo "  Success patterns: $success_count"
    echo "  Failure patterns: $failure_count"
    echo ""
    
    # Reminder
    echo -e "${PURPLE}Remember:${NC}"
    echo "  • You (Claude Code) handle synthesis and decisions"
    echo "  • Ollama handles parallel exploration and challenges"
    echo "  • This respects your Claude Max subscription"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

usage() {
    echo "Night Architecture - Tier Router"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  explore <topic>           Run parallel exploration (3 perspectives)"
    echo "  challenge <proposal>      Run Devil's Advocate challenge"
    echo "  review <code_file>        Run code review (security, performance, maintainability)"
    echo "  pattern success <task> <approach>   Capture success pattern"
    echo "  pattern failure <task> <issue>      Capture failure pattern"
    echo "  patterns search <query>   Search patterns"
    echo "  status                    Show system status"
    echo ""
    echo "Examples:"
    echo "  $0 explore \"Should we use microservices or monolith?\""
    echo "  $0 challenge \"My plan is to use PostgreSQL with JSONB for all data\""
    echo "  $0 review ./src/auth.py"
    echo "  $0 pattern success \"JWT auth\" \"Used refresh token rotation\""
    echo "  $0 patterns search \"authentication\""
    echo ""
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

case "${1:-}" in
    explore)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 explore <topic>"
            exit 1
        fi
        run_exploration "$2" "${3:-}"
        ;;
    challenge)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 challenge <proposal>"
            exit 1
        fi
        run_challenge "$2"
        ;;
    review)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 review <code_file>"
            exit 1
        fi
        run_review "$2" "${3:-}"
        ;;
    pattern)
        case "${2:-}" in
            success)
                capture_pattern "success" "${3:-}" "${4:-}"
                ;;
            failure)
                capture_pattern "failure" "${3:-}" "${4:-}"
                ;;
            *)
                echo "Usage: $0 pattern <success|failure> <task> <details>"
                exit 1
                ;;
        esac
        ;;
    patterns)
        if [ "${2:-}" = "search" ]; then
            search_patterns "${3:-}"
        else
            echo "Usage: $0 patterns search <query>"
            exit 1
        fi
        ;;
    status)
        show_status
        ;;
    *)
        usage
        ;;
esac
