# Night Architecture: Multi-Agent Development System

## For Claude Code: Project Summary & Execution Guide

**Owner:** Rado (Senior Systems Architect)
**Purpose:** Legitimate multi-agent autonomous development within Claude Max subscription bounds
**Hardware:** NVIDIA 5090 GPU in WSL for local inference

---

## What We're Building

Night Architecture is a **tiered multi-agent development system** that maximizes the value of a Claude Max subscription while adding parallel processing capability through local inference. It's designed for a power user who wants sophisticated autonomous development without violating terms of service or burning expensive API tokens unnecessarily.

### The Core Problem We're Solving

1. **Claude Max is valuable but has limits** - Weekly caps of 140-280 hours for Max 5x ($100/month)
2. **API tokens are expensive** - $3-15+ per million tokens adds up fast for agent loops
3. **Single-agent bottlenecks** - One perspective can miss issues or fall into local optima
4. **Groupthink in AI systems** - Without deliberate dissent, agents converge too quickly

### Our Solution: Intelligent Tiering + Anti-Groupthink Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    NIGHT ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  TIER 1: Claude Max (Your Subscription)                     │   │
│  │  ═══════════════════════════════════════                    │   │
│  │  • Primary agent work via Claude Code CLI                   │   │
│  │  • High-quality synthesis and critical decisions            │   │
│  │  • Architecture design, code review, final approval         │   │
│  │  • Natural pacing (not automated bombardment)               │   │
│  │  • Cost: $0 additional (already paid)                       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  TIER 2: Ollama Local (5090 GPU)                            │   │
│  │  ═══════════════════════════════════                        │   │
│  │  • Parallel exploration agents (multiple perspectives)      │   │
│  │  • Devil's Advocate challenges (anti-groupthink)            │   │
│  │  • Bulk analysis and iteration                              │   │
│  │  • Draft generation before Claude review                    │   │
│  │  • Cost: $0 (your electricity only)                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  TIER 3: Anthropic API (Emergency Only)                     │   │
│  │  ═══════════════════════════════════════                    │   │
│  │  • Only when Max is rate-limited AND Ollama fails           │   │
│  │  • Use batch API (50% discount) when possible               │   │
│  │  • Prompt caching for repeated contexts (90% savings)       │   │
│  │  • Cost: Pay-per-token (avoid when possible)                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Why This Architecture?

### Anthropic's Acceptable Use (What We Learned)

Through research, we confirmed:

1. **Claude Code + Max IS designed for agentic work** - Planning, executing, iterating is the intended use
2. **The crackdown was on abuse** - Third-party tools spoofing Claude Code, 24/7 CI/CD pipelines consuming $10k+/month in compute
3. **Weekly caps exist** - Max 5x gets 140-280 hours/week, which naturally throttles extreme automation
4. **No bulk API discounts** - But batch API (50% off) and prompt caching (90% off reads) help

### What's Legitimate vs. Problematic

| ✅ Legitimate (Our Approach) | ❌ Problematic (Avoid) |
|------------------------------|------------------------|
| Interactive Claude Code sessions | 24/7 unattended automation |
| Multi-step tasks you initiate | Third-party tools spoofing Claude |
| Natural pacing with breaks | Hundreds of `claude -p` calls/hour |
| Overnight work with checkpoints | CI/CD pipelines on subscription |
| Local Ollama for parallel work | Swarms hitting Claude Max directly |

### The Anti-Groupthink Innovation

Research shows AI agents (like humans) suffer from groupthink - premature consensus without exploring alternatives. Our solution:

**Devil's Advocate Pattern** (via Ollama - free!)
- Dedicated agents that MUST challenge proposals
- Voice but not veto - they raise concerns, don't block
- Socratic questioning to surface assumptions
- Multiple perspectives before synthesis

**Manager Cross-Review** (via Ollama - free!)
- Two manager agents review each other's decisions
- Prevents single points of failure in oversight
- Evidence-based dispute resolution

**Pattern Banking** (local storage)
- Store successful approaches for reuse
- Track anti-patterns to avoid
- Enable genuine learning over time

---

## Architecture Components

### Agent Roles

```
EXECUTION LAYER (Do the work)
├── Architect Agent    - System design, technical decisions
├── Coder Agent        - Implementation with tests
├── Tester Agent       - Comprehensive test creation
└── Reviewer Agent     - Quality, security, performance review

OVERSIGHT LAYER (Ensure quality)
├── Manager A          - Quality gates, groupthink detection
├── Manager B          - Evolution tracking, optimization
└── Devil's Advocate   - Challenge consensus, surface risks

LEARNING LAYER (Improve over time)
├── Pattern Bank       - Store success/failure patterns
└── Evolution Engine   - Tune agent prompts based on outcomes
```

### Execution Flow

```
1. TASK INTAKE
   └── User provides task via Claude Code

2. PARALLEL EXPLORATION (Ollama - Free)
   ├── Agent A: Conservative approach
   ├── Agent B: Aggressive approach  
   ├── Agent C: Alternative framing
   └── Devil's Advocate: What could go wrong?

3. SYNTHESIS (Claude Max - Subscription)
   └── Claude Code synthesizes perspectives into plan

4. IMPLEMENTATION (Claude Max - Subscription)
   └── Claude Code implements with full context

5. REVIEW CYCLE (Ollama + Claude Max)
   ├── Ollama agents review for issues
   └── Claude Max makes final decision

6. PATTERN CAPTURE (Local)
   └── Store what worked/failed for future
```

---

## File Structure

```
night-architecture-legitimate/
├── README.md                      # This file - project overview
├── CLAUDE-CODE-INSTRUCTIONS.md    # Direct instructions for Claude Code
│
├── config/
│   ├── agents.yaml                # Agent definitions and prompts
│   ├── tiers.yaml                 # Inference tier configuration
│   └── patterns.yaml              # Pattern bank schema
│
├── scripts/
│   ├── setup.sh                   # Initial setup script
│   ├── ollama-setup.sh            # Ollama configuration for WSL
│   ├── tier-router.sh             # Routes requests to appropriate tier
│   └── session-manager.sh         # Manages work sessions with pacing
│
├── agents/
│   ├── architect.md               # Architect agent prompt
│   ├── coder.md                   # Coder agent prompt
│   ├── reviewer.md                # Reviewer agent prompt
│   ├── devils-advocate.md         # Devil's Advocate prompt
│   └── manager.md                 # Manager agent prompt
│
├── workflows/
│   ├── standard-task.md           # Normal task workflow
│   ├── complex-task.md            # Multi-phase task workflow
│   └── overnight-session.md       # Extended session workflow
│
└── patterns/
    ├── successes/                 # Successful pattern storage
    ├── failures/                  # Anti-pattern storage
    └── templates/                 # Reusable templates
```

---

## Hardware Requirements

### Rado's Setup
- **GPU:** NVIDIA 5090 in WSL
- **Ollama Model:** qwen3-coder (or similar 64k+ context model)
- **Claude:** Max 5x subscription ($100/month)

### Minimum Requirements
- Any CUDA-capable GPU with 16GB+ VRAM for local inference
- Claude Pro or Max subscription
- WSL2 or native Linux

---

## Key Principles

### 1. Respect the Subscription
- Use Claude Code as intended - interactive, with human oversight
- Don't try to automate around rate limits
- Natural pacing, not bombardment

### 2. Offload to Local When Appropriate
- Parallel exploration → Ollama (free, unlimited)
- Draft generation → Ollama
- Devil's advocate challenges → Ollama
- Final synthesis → Claude Max (quality matters)

### 3. Anti-Groupthink by Design
- Always get multiple perspectives before deciding
- Devil's Advocate is mandatory, not optional
- Capture dissenting views even when overruled

### 4. Learn and Improve
- Store patterns from successful tasks
- Track what went wrong and why
- Evolve agent prompts based on outcomes

### 5. Transparency
- Clear logging of which tier handled what
- Track "savings" from local inference
- Morning briefings after overnight sessions

---

## Getting Started

### For Claude Code

When Claude Code receives this project, it should:

1. **Read `CLAUDE-CODE-INSTRUCTIONS.md`** first for specific execution guidance
2. **Run `scripts/setup.sh`** to initialize the environment
3. **Configure Ollama** via `scripts/ollama-setup.sh`
4. **Start accepting tasks** using the workflow documents

### Quick Start Commands

```bash
# Initial setup
cd night-architecture-legitimate
./scripts/setup.sh

# Configure Ollama for WSL with 5090
./scripts/ollama-setup.sh

# Start a standard task session
./scripts/session-manager.sh start "Build a REST API for user management"

# Check system status
./scripts/tier-router.sh status
```

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Claude Max usage efficiency | >90% valuable work |
| Local inference utilization | >50% of total calls |
| API token burn | <$10/month |
| Task completion rate | >85% |
| Anti-groupthink challenge rate | 100% (every decision challenged) |

---

## Philosophy: Night Architecture

The name "Night Architecture" reflects:

1. **Overnight capability** - Extended sessions while you sleep
2. **Architectural thinking** - System design, not just coding
3. **Rado's Night Architecture blog/podcast** - AI consciousness and transhumanism themes
4. **The bat symbolism** - Navigating in darkness, echolocation as multi-perspective sensing

This system embodies the idea that good architecture emerges from multiple perspectives, deliberate challenge, and iterative refinement - whether in software, organizations, or AI systems themselves.

---

## License & Attribution

Created for Rado's personal use. Architecture patterns inspired by:
- Multi-Agent Reflexion (MAR) research
- Devil's Advocate decision-making literature
- Claude-Flow v3 patterns
- Gödel Agent self-improvement concepts

Built with Claude (Anthropic) in January 2026.
