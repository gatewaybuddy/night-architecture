# Night Architecture - Quick Reference

## Common Commands

### Session Management
```bash
# Start a work session (default 8 hours)
./scripts/session-manager.sh start "my-project"

# Start with custom duration
./scripts/session-manager.sh start "my-project" 4

# Check session status
./scripts/session-manager.sh status

# Create checkpoint
./scripts/session-manager.sh checkpoint "Completed auth module"

# Mark task complete
./scripts/session-manager.sh complete-task "Implemented user login"

# Mark task failed
./scripts/session-manager.sh fail-task "Rate limiting" "Redis connection issues"

# End session (generates briefing)
./scripts/session-manager.sh end
```

### Exploration & Challenge
```bash
# Get multiple perspectives (runs 3 Ollama agents in parallel)
./scripts/tier-router.sh explore "Should we use microservices or monolith?"

# Challenge a proposal (runs Devil's Advocate)
./scripts/tier-router.sh challenge "My plan is to use PostgreSQL with JSONB..."

# Review code (security, performance, maintainability)
./scripts/tier-router.sh review ./src/auth.py
```

### Pattern Management
```bash
# Capture success pattern
./scripts/tier-router.sh pattern success "JWT auth" "Used refresh token rotation"

# Capture failure pattern
./scripts/tier-router.sh pattern failure "localStorage tokens" "XSS vulnerability"

# Search patterns
./scripts/tier-router.sh patterns search "authentication"
```

### System Status
```bash
# Check everything
./scripts/tier-router.sh status

# Check Ollama specifically
curl http://localhost:11434/api/tags
```

## Workflow Reminders

### Before Major Decisions
1. Run exploration for perspectives
2. Synthesize into your proposal
3. Run Devil's Advocate challenge
4. Address or acknowledge concerns
5. Proceed with implementation

### After Completing Work
1. Run code review
2. Address findings
3. Mark task complete
4. Capture patterns
5. Create checkpoint

### Starting/Ending Day
- Start: `./scripts/session-manager.sh start`
- End: `./scripts/session-manager.sh end`
- Review the generated briefing

## Tier Usage

| Task Type | Use This Tier |
|-----------|---------------|
| Exploration (multiple perspectives) | Ollama (free) |
| Devil's Advocate challenges | Ollama (free) |
| Code review (initial) | Ollama (free) |
| Draft generation | Ollama (free) |
| Synthesis & decisions | Claude Code (subscription) |
| Implementation | Claude Code (subscription) |
| Final review | Claude Code (subscription) |
| Complex reasoning | Claude Code (subscription) |

## Emergency Commands

```bash
# If Ollama is down
./scripts/ollama-setup.sh

# Reset session state (if corrupted)
rm ./state/session.json
./scripts/setup.sh

# Check logs
tail -f ./logs/tier-router.log
tail -f ./logs/session.log
```

## File Locations

```
./config/agents.yaml     # Agent configurations
./state/session.json     # Current session state
./state/checkpoints/     # Session checkpoints
./patterns/successes/    # Success patterns
./patterns/failures/     # Failure patterns
./logs/                  # All logs
```

---
🦇 Night Architecture
