#!/bin/bash
#
# Night Architecture - Session Manager
# Manages work sessions with appropriate pacing and checkpoints
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

STATE_FILE="$PROJECT_DIR/state/session.json"
CHECKPOINT_DIR="$PROJECT_DIR/state/checkpoints"
LOG_FILE="$PROJECT_DIR/logs/session.log"

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
    
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        INFO)    echo -e "${BLUE}ℹ${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}✓${NC} $message" ;;
        WARN)    echo -e "${YELLOW}⚠${NC} $message" ;;
        ERROR)   echo -e "${RED}✗${NC} $message" ;;
    esac
}

# =============================================================================
# SESSION MANAGEMENT
# =============================================================================

start_session() {
    local session_name="${1:-session_$(date +%Y%m%d_%H%M%S)}"
    local max_hours="${2:-8}"
    
    local start_time=$(date -Iseconds)
    local end_time=$(date -d "+${max_hours} hours" -Iseconds)
    
    # Create session record
    local session_data=$(jq -n \
        --arg name "$session_name" \
        --arg start "$start_time" \
        --arg end "$end_time" \
        --argjson max_hours "$max_hours" \
        '{
            name: $name,
            started_at: $start,
            max_end_time: $end,
            max_hours: $max_hours,
            tasks_completed: 0,
            tasks_failed: 0,
            checkpoints: [],
            status: "active"
        }')
    
    # Update state
    jq --argjson session "$session_data" '.current_session = $session | .last_active = now | .last_active |= todate' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    mkdir -p "$CHECKPOINT_DIR/$session_name"
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║   🦇  NIGHT ARCHITECTURE - SESSION STARTED                     ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Session:    $session_name"
    echo "  Started:    $start_time"
    echo "  Max End:    $end_time"
    echo "  Max Hours:  $max_hours"
    echo ""
    echo "  Checkpoints will be saved to:"
    echo "  $CHECKPOINT_DIR/$session_name/"
    echo ""
    echo "  Commands:"
    echo "    ./scripts/session-manager.sh checkpoint \"description\""
    echo "    ./scripts/session-manager.sh complete-task \"task description\""
    echo "    ./scripts/session-manager.sh fail-task \"task description\" \"reason\""
    echo "    ./scripts/session-manager.sh end"
    echo ""
    
    log SUCCESS "Session started: $session_name"
}

create_checkpoint() {
    local description=$1
    
    # Get current session
    local session_name=$(jq -r '.current_session.name // empty' "$STATE_FILE")
    
    if [ -z "$session_name" ]; then
        log ERROR "No active session. Start one with: ./scripts/session-manager.sh start"
        return 1
    fi
    
    local checkpoint_id="checkpoint_$(date +%Y%m%d_%H%M%S)"
    local checkpoint_file="$CHECKPOINT_DIR/$session_name/${checkpoint_id}.json"
    
    # Create checkpoint
    jq -n \
        --arg id "$checkpoint_id" \
        --arg desc "$description" \
        --arg time "$(date -Iseconds)" \
        '{
            id: $id,
            description: $desc,
            created_at: $time
        }' > "$checkpoint_file"
    
    # Update session
    jq --arg cp "$checkpoint_id" \
        '.current_session.checkpoints += [$cp]' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    log SUCCESS "Checkpoint created: $checkpoint_id"
    echo "  Description: $description"
    echo "  File: $checkpoint_file"
}

complete_task() {
    local task_desc=$1
    
    # Update session
    jq '.current_session.tasks_completed += 1 | .total_tasks_completed += 1' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    log SUCCESS "Task completed: $task_desc"
    
    # Auto-checkpoint
    create_checkpoint "Completed: $task_desc"
}

fail_task() {
    local task_desc=$1
    local reason="${2:-Unknown reason}"
    
    # Update session
    jq '.current_session.tasks_failed += 1' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    log WARN "Task failed: $task_desc"
    echo "  Reason: $reason"
    
    # Capture failure pattern
    "$SCRIPT_DIR/tier-router.sh" pattern failure "$task_desc" "$reason"
    
    # Check consecutive failures
    local failed=$(jq -r '.current_session.tasks_failed' "$STATE_FILE")
    if [ "$failed" -ge 3 ]; then
        log WARN "3 consecutive failures detected. Consider stopping and reviewing."
    fi
}

end_session() {
    local session_name=$(jq -r '.current_session.name // empty' "$STATE_FILE")
    
    if [ -z "$session_name" ]; then
        log ERROR "No active session to end"
        return 1
    fi
    
    local end_time=$(date -Iseconds)
    local tasks_completed=$(jq -r '.current_session.tasks_completed' "$STATE_FILE")
    local tasks_failed=$(jq -r '.current_session.tasks_failed' "$STATE_FILE")
    local checkpoints=$(jq -r '.current_session.checkpoints | length' "$STATE_FILE")
    
    # Generate briefing
    generate_briefing "$session_name" "$tasks_completed" "$tasks_failed" "$checkpoints"
    
    # Update session status
    jq --arg end "$end_time" \
        '.current_session.ended_at = $end | .current_session.status = "completed"' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    # Archive session
    local archive_file="$CHECKPOINT_DIR/$session_name/session_summary.json"
    jq '.current_session' "$STATE_FILE" > "$archive_file"
    
    # Clear current session
    jq '.current_session = null' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    
    log SUCCESS "Session ended: $session_name"
}

generate_briefing() {
    local session_name=$1
    local tasks_completed=$2
    local tasks_failed=$3
    local checkpoints=$4
    
    local briefing_file="$CHECKPOINT_DIR/$session_name/briefing.md"
    local start_time=$(jq -r '.current_session.started_at' "$STATE_FILE")
    local ollama_calls=$(jq -r '.total_ollama_calls' "$STATE_FILE")
    
    cat > "$briefing_file" << EOF
# 🦇 Night Architecture - Session Briefing

**Session:** $session_name
**Period:** $start_time to $(date -Iseconds)

## Summary

| Metric | Count |
|--------|-------|
| Tasks Completed | $tasks_completed |
| Tasks Failed | $tasks_failed |
| Checkpoints | $checkpoints |

## Resource Usage

- **Claude Code:** Used for synthesis and decisions (subscription)
- **Ollama Calls:** $ollama_calls (free)
- **API Calls:** 0 (avoided!)

## Checkpoints

$(ls -1 "$CHECKPOINT_DIR/$session_name/"checkpoint_*.json 2>/dev/null | while read -r f; do
    jq -r '"- \(.created_at): \(.description)"' "$f"
done || echo "No checkpoints recorded")

## Patterns Captured

### Successes
$(ls -1t "$PROJECT_DIR/patterns/successes/"*.json 2>/dev/null | head -5 | while read -r f; do
    jq -r '"- \(.task)"' "$f"
done || echo "None this session")

### Failures (Lessons Learned)
$(ls -1t "$PROJECT_DIR/patterns/failures/"*.json 2>/dev/null | head -5 | while read -r f; do
    jq -r '"- \(.task): \(.issue)"' "$f"
done || echo "None this session")

## Next Steps

Review this briefing and:
1. Check any failed tasks that need attention
2. Review captured patterns for future reference
3. Plan the next session based on remaining work

---
*Generated by Night Architecture Session Manager*
EOF

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                    SESSION BRIEFING"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    cat "$briefing_file"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "Briefing saved to: $briefing_file"
    echo "════════════════════════════════════════════════════════════════"
}

show_session_status() {
    local session_name=$(jq -r '.current_session.name // empty' "$STATE_FILE")
    
    if [ -z "$session_name" ]; then
        echo "No active session."
        echo "Start one with: ./scripts/session-manager.sh start"
        return
    fi
    
    local start_time=$(jq -r '.current_session.started_at' "$STATE_FILE")
    local max_end=$(jq -r '.current_session.max_end_time' "$STATE_FILE")
    local tasks_completed=$(jq -r '.current_session.tasks_completed' "$STATE_FILE")
    local tasks_failed=$(jq -r '.current_session.tasks_failed' "$STATE_FILE")
    local checkpoints=$(jq -r '.current_session.checkpoints | length' "$STATE_FILE")
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           CURRENT SESSION STATUS                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Session:          $session_name"
    echo "  Started:          $start_time"
    echo "  Max End Time:     $max_end"
    echo ""
    echo "  Tasks Completed:  $tasks_completed"
    echo "  Tasks Failed:     $tasks_failed"
    echo "  Checkpoints:      $checkpoints"
    echo ""
    
    # Time remaining
    local now=$(date +%s)
    local end=$(date -d "$max_end" +%s)
    local remaining=$((end - now))
    
    if [ $remaining -gt 0 ]; then
        local hours=$((remaining / 3600))
        local minutes=$(((remaining % 3600) / 60))
        echo -e "  Time Remaining:   ${GREEN}${hours}h ${minutes}m${NC}"
    else
        echo -e "  Time Remaining:   ${RED}EXCEEDED${NC}"
    fi
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

usage() {
    echo "Night Architecture - Session Manager"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start [name] [max_hours]    Start a new session (default: 8 hours)"
    echo "  checkpoint <description>    Create a checkpoint"
    echo "  complete-task <description> Mark a task as completed"
    echo "  fail-task <desc> [reason]   Mark a task as failed"
    echo "  status                      Show current session status"
    echo "  end                         End the current session"
    echo ""
    echo "Examples:"
    echo "  $0 start \"api-development\" 6"
    echo "  $0 checkpoint \"Completed user authentication\""
    echo "  $0 complete-task \"Implemented JWT auth with refresh tokens\""
    echo "  $0 fail-task \"Rate limiting\" \"Redis connection issues\""
    echo "  $0 end"
    echo ""
}

# Ensure directories exist
mkdir -p "$CHECKPOINT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Ensure state file exists
if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" << 'EOF'
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
fi

case "${1:-}" in
    start)
        start_session "${2:-}" "${3:-8}"
        ;;
    checkpoint)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 checkpoint <description>"
            exit 1
        fi
        create_checkpoint "$2"
        ;;
    complete-task)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 complete-task <description>"
            exit 1
        fi
        complete_task "$2"
        ;;
    fail-task)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 fail-task <description> [reason]"
            exit 1
        fi
        fail_task "$2" "${3:-}"
        ;;
    status)
        show_session_status
        ;;
    end)
        end_session
        ;;
    *)
        usage
        ;;
esac
