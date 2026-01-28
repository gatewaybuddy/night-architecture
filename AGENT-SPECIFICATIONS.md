# AI Agent Specifications

**Purpose:** Detailed specifications for development agents based on cross-project learnings
**Status:** Ready for Implementation
**Priority Order:** Foundation → Workflow → Quality & Optimization

---

## Foundation Agents (Priority 1)

### Agent 1: Session Resume Agent

**Purpose:** Eliminate context loss between work sessions

**Inputs:**
- `project_dir` (path): Project root directory
- `lookback_commits` (int): Number of git commits to scan (default: 10)

**Process:**
1. Read `CLAUDE.md` for project overview
2. Find most recent completion document:
   - `PHASE_N_IMPLEMENTATION.md`
   - `SESSION_SUMMARY_*.md`
   - `.claude/sessions.jsonl` (last entry)
3. Scan last N git commits:
   - Extract commit messages
   - Identify files changed
   - Detect patterns (feature, bug fix, refactor)
4. Check `.claude/tasks/current.json` for active tasks
5. Load `.claude/memory/patterns.json` for project learnings

**Outputs:**
```json
{
  "last_session": {
    "date": "2026-01-25",
    "phase": "Phase 3: Memory System",
    "completion_percentage": 80,
    "files_changed": ["src/memory/EpisodicMemory.java", "..."],
    "status": "In Progress"
  },
  "active_tasks": [
    {"id": "T042", "title": "Implement semantic memory consolidation", "priority": "P1"}
  ],
  "next_steps": [
    "Complete semantic memory consolidation (T042)",
    "Write unit tests for memory queries",
    "Update PHASE_3_IMPLEMENTATION.md"
  ],
  "context_summary": "Working on memory system. Episodic memory complete, semantic memory 50% done. Need to implement consolidation logic.",
  "learnings": ["Always test memory limits", "Use LRU cache for working memory"]
}
```

**Usage:**
```bash
# At start of session
claude-agent session-resume /path/to/project

# Output used to prime Claude with full context
```

**Success Criteria:**
- Context gathering time: 15min → 2min (87% reduction)
- Accuracy: 95%+ identification of stopping point
- Zero repeated questions about project status

**Implementation Notes:**
- Parse git log with `--pretty=format:"%h %s"`
- Use tree-sitter for code analysis if needed
- Cache patterns in `.claude/memory/patterns.json`

---

### Agent 2: Task Card Generator

**Purpose:** Auto-generate structured task cards from changes or requests

**Inputs:**
- `source_type` (enum): "git_diff" | "feature_request" | "bug_report"
- `source_content` (string): Diff text, request description, or bug details
- `project_context` (path): Project CLAUDE.md for reference

**Process:**
1. Parse source content:
   - **git_diff:** Extract files changed, additions/deletions
   - **feature_request:** Extract requirements, user story
   - **bug_report:** Extract error, expected vs actual, steps to reproduce
2. Classify task type:
   - Feature: New functionality
   - Bug Fix: Error correction
   - Refactor: Code restructure (no behavior change)
   - Docs: Documentation update
   - Test: Test addition
3. Generate task ID (auto-increment from last)
4. Infer priority:
   - P0: Security, crashes, data loss
   - P1: Core functionality, user-facing bugs
   - P2: Nice-to-have, minor bugs
5. Extract acceptance criteria (testable/measurable)
6. Identify dependencies (from git history or explicit mentions)

**Outputs:**
```json
{
  "task_id": "T043",
  "title": "Add semantic memory consolidation to AI players",
  "type": "feature",
  "priority": "P1",
  "status": "planned",
  "dependencies": ["T041", "T042"],
  "acceptance_criteria": [
    "Semantic memory stores facts extracted from episodic events",
    "Facts retrieved in <50ms for goal planning",
    "Memory consolidation runs every 100 ticks",
    "Unit tests cover edge cases (empty memory, duplicate facts)"
  ],
  "estimated_effort": "4 hours",
  "files_affected": [
    "src/memory/SemanticMemory.java",
    "src/memory/MemoryConsolidator.java",
    "test/memory/SemanticMemoryTest.java"
  ],
  "notes": "Builds on episodic memory (T042). Uses NLP for fact extraction."
}
```

**Usage:**
```bash
# From git diff
git diff main..feature-branch | claude-agent task-generate --source git_diff

# From feature request
claude-agent task-generate --source feature_request --content "Users want to export data as CSV"

# Auto-mode (scans last commit)
claude-agent task-generate --auto
```

**Success Criteria:**
- Generation time: <30 seconds for 10 tasks
- Accuracy: 90%+ correct priority/type classification
- Completeness: 100% have acceptance criteria

**Implementation Notes:**
- Use regex patterns for common task patterns
- LLM (GPT-3.5) for complex analysis
- Learn from manual corrections (`.claude/memory/task-corrections.json`)

---

### Agent 3: CLAUDE.md Generator

**Purpose:** Bootstrap new projects with context documentation

**Inputs:**
- `project_dir` (path): Project root to analyze
- `template_type` (enum): "auto" | "python" | "java" | "javascript" | "rust"

**Process:**
1. **Detect Project Type:**
   - Scan for: `package.json`, `pom.xml`, `requirements.txt`, `Cargo.toml`, etc.
   - Identify frameworks: React, Spring Boot, FastAPI, etc.
2. **Extract Tech Stack:**
   - Language version
   - Frameworks & libraries
   - Database (from config files)
   - Build tools (Maven, npm, pip, cargo)
3. **Map Directory Structure:**
   - Source directories
   - Test directories
   - Config files
   - Documentation
4. **Find Build Commands:**
   - Parse `package.json` scripts
   - Check `pom.xml` plugins
   - Look for Makefile, scripts/
5. **Identify Key Files:**
   - Entry points (main.py, index.js, Main.java)
   - Config files (.env.example, application.yml)
   - Important modules (by import frequency)
6. **Detect Conventions:**
   - Naming patterns (PascalCase, snake_case)
   - Test framework (JUnit, pytest, Jest)
   - Linting/formatting (.eslintrc, .prettierrc)
7. **Generate CLAUDE.md** using template

**Outputs:**
File: `CLAUDE.md` with structure:
```markdown
# CLAUDE.md - [Project Name]

## Project Overview
[Auto-detected type and purpose]

## Tech Stack
- **Language:** Python 3.11
- **Framework:** FastAPI 0.104.0
- **Database:** PostgreSQL 15
- **Libraries:** SQLAlchemy, Celery, Redis

## Repository Structure
```
src/
  api/        # REST endpoints
  models/     # Database models
  services/   # Business logic
tests/
  unit/       # Unit tests
  integration/ # Integration tests
```

## Development Commands
```bash
# Install dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Start server
uvicorn app.main:app --reload
```

## Architecture
[High-level design - placeholder for manual update]

## Key Files
- src/main.py - Application entry point
- src/config.py - Configuration management
- .env.example - Environment variables template

## Conventions
- Naming: snake_case for functions/variables
- Testing: pytest with fixtures in conftest.py
- Code style: Black formatter, ruff linter

## Constraints
[Placeholder for manual addition]
```

**Usage:**
```bash
# Auto-detect everything
claude-agent claude-md-generate /path/to/project

# Specify project type
claude-agent claude-md-generate /path/to/project --type python

# Update existing CLAUDE.md (merge, don't overwrite)
claude-agent claude-md-generate /path/to/project --update
```

**Success Criteria:**
- Generation time: <2 minutes per project
- Accuracy: 95%+ correct tech stack detection
- Completeness: All sections populated (Architecture/Constraints may be placeholders)

**Implementation Notes:**
- Use file system traversal (limited depth)
- Parse JSON/XML/YAML with standard libraries
- Template engine for markdown generation
- Store learned patterns in `.claude-organizer/project-patterns.json`

---

### Agent 4: Documentation Sync Agent

**Purpose:** Keep CLAUDE.md and docs current with code changes

**Inputs:**
- `git_hook_event` (enum): "pre-commit" | "post-commit" | "pre-push"
- `changed_files` (list): Files modified in commit
- `commit_message` (string): Commit message text

**Process:**
1. **Detect Documentation Impact:**
   - API endpoint added/removed/changed → Update endpoint list
   - Config variable added → Update .env.example section
   - New major file → Add to "Key Files" section
   - Tech stack change (package.json, requirements.txt) → Update dependencies
2. **Parse Code Changes:**
   - New functions/classes → Check if public API
   - Changed function signatures → Flag as breaking change
   - Removed code → Check if documented
3. **Update CLAUDE.md:**
   - Modify relevant sections
   - Maintain format consistency
   - Add changelog entry
4. **Flag Outdated Docs:**
   - Find docs mentioning changed code
   - Create list of files to review
5. **Generate Changelog:**
   - Semantic versioning hints (major/minor/patch)
   - Breaking changes highlighted

**Outputs:**
```json
{
  "action": "update",
  "files_updated": ["CLAUDE.md", "CHANGELOG.md"],
  "changes": [
    {
      "file": "CLAUDE.md",
      "section": "API Endpoints",
      "change": "Added POST /api/v1/campaigns/{id}/auto-deploy"
    }
  ],
  "warnings": [
    {
      "file": "README.md",
      "line": 42,
      "reason": "References removed function `oldFunction()`"
    }
  ],
  "changelog_entry": {
    "version": "1.3.0",
    "type": "minor",
    "changes": [
      "feat: Add auto-deploy endpoint for campaigns"
    ],
    "breaking_changes": []
  }
}
```

**Usage:**
```bash
# As git pre-commit hook
.git/hooks/pre-commit:
  claude-agent doc-sync --hook pre-commit --files $(git diff --cached --name-only)

# Manual sync
claude-agent doc-sync --project /path/to/project

# Dry run (show what would change)
claude-agent doc-sync --dry-run
```

**Success Criteria:**
- Sync time: <10 seconds per commit
- Accuracy: 95%+ correct impact detection
- False positives: <10% (flagging non-breaking changes)

**Implementation Notes:**
- AST parsing for API surface changes
- Diff analysis for removed references
- Semantic versioning rules from conventional commits
- Configurable ignore patterns (`.claude/doc-sync-ignore.json`)

---

### Agent 5: Voice Validator (Content Quality)

**Purpose:** Ensure consistent voice/tone in content

**Inputs:**
- `content_file` (path): Markdown file to validate
- `voice_guidelines` (path): JSON file with rules (default: `.claude/voice-guidelines.json`)
- `mode` (enum): "strict" | "normal" | "lenient"

**Process:**
1. **Load Voice Guidelines:**
   ```json
   {
     "red_flags": [
       {"pattern": "passive voice", "regex": "\\b(was|were|been|being)\\s+\\w+ed\\b"},
       {"pattern": "no I statements", "check": "sentence_count_with_I < total_sentences * 0.3"},
       {"pattern": "jargon overload", "words": ["synergy", "leverage", "paradigm"]}
     ],
     "green_lights": [
       {"pattern": "personal pronouns", "check": "uses I/we/my"},
       {"pattern": "concrete examples", "check": "has code blocks or specific scenarios"}
     ],
     "tone": {
       "target": "conversational",
       "avoid": ["academic", "corporate", "overly formal"]
     }
   }
   ```
2. **Analyze Content:**
   - Sentence-by-sentence scan for red flags
   - Count personal pronouns (I, we, my, our)
   - Detect passive voice constructions
   - Check for jargon from blocklist
   - Measure readability (Flesch score)
   - Identify overly complex sentences (>25 words)
3. **Score Authenticity (0-100):**
   - Start at 100
   - -20 for each red flag instance
   - +10 for each green light
   - -5 for readability < target
4. **Generate Specific Fixes:**
   - Line number + current text + suggested replacement

**Outputs:**
```json
{
  "overall_score": 75,
  "verdict": "good",
  "red_flags": [
    {
      "line": 12,
      "issue": "passive voice",
      "current": "The system was designed to handle...",
      "suggested": "I designed the system to handle..."
    },
    {
      "line": 24,
      "issue": "jargon",
      "current": "leveraging synergies",
      "suggested": "combining strengths" or "working together"
    }
  ],
  "green_lights": [
    {"line": 3, "pattern": "personal example", "text": "I built this because..."}
  ],
  "statistics": {
    "total_sentences": 45,
    "sentences_with_I": 18,
    "I_percentage": 40,
    "passive_voice_count": 2,
    "jargon_count": 1,
    "avg_sentence_length": 18,
    "flesch_score": 65
  },
  "suggestions": [
    "Great use of personal voice (40% sentences use 'I')",
    "Reduce passive voice (2 instances found)",
    "Consider simpler alternatives for jargon"
  ]
}
```

**Usage:**
```bash
# Validate single file
claude-agent voice-validate content/blog-001.md

# Validate all content
claude-agent voice-validate content/*.md --mode strict

# Auto-fix mode (applies suggestions)
claude-agent voice-validate content/blog-001.md --fix
```

**Success Criteria:**
- Validation time: <5 seconds per 5K words
- Accuracy: 90%+ correct red flag detection
- Usefulness: 80%+ of suggestions improve quality

**Implementation Notes:**
- Use spaCy or NLTK for NLP analysis
- Regex for quick pattern matching
- LLM (GPT-3.5) for suggested rewrites
- Learn from manual overrides (`.claude/voice-overrides.json`)

---

## Workflow Agents (Priority 2)

### Agent 6: Compilation Generator (Content)

**Purpose:** Automate Phase 1 of content creation (thematic compilation)

**Inputs:**
- `source_files` (list): Conversation IDs or markdown files
- `theme` (string): Topic or theme for compilation
- `target_length` (int): Word count target (default: 14000)

**Process:**
1. **Load Sources in Parallel:**
   - Read 4-6 files simultaneously
   - Extract key topics/entities from each
   - Build topic frequency map
2. **Organize Thematically:**
   - Group related conversations
   - Identify narrative arc (beginning → middle → end)
   - Find natural transitions
3. **Extract Quotes:**
   - Preserve authentic voice
   - Select most impactful passages
   - Note context for each quote
4. **Generate Narrative:**
   - Intro: Why this theme matters
   - Body: Organized by sub-topics
   - Conclusion: Key takeaways
5. **Format Output:**
   - Markdown with clear sections
   - Quote blocks with attributions
   - Cross-references to sources

**Outputs:**
File: `[theme]-compilation.md` (14K words)
```markdown
# [Theme] - Thematic Compilation

## Overview
[Why this collection matters, 200-300 words]

## Part 1: [Sub-topic]
[Narrative with quotes]

> "Key quote from conversation 42"
> — Conversation 42: [Title]

[Analysis and connections]

## Part 2: [Sub-topic]
...

## Key Takeaways
- Insight 1
- Insight 2
- Insight 3

## Source Conversations
- Conversation 12: [Title] ([date])
- Conversation 24: [Title] ([date])
...
```

**Success Criteria:**
- Generation time: <5 minutes for 14K words
- Quality: Coherent narrative (human review: 85%+ approval)
- Coverage: All source conversations represented

---

### Agent 7: Phase Completion Doc Generator

**Purpose:** Auto-document what was built in a development phase

**Inputs:**
- `phase_name` (string): e.g., "Phase 3: Memory System"
- `branch_name` (string): Git branch for this phase
- `base_branch` (string): Branch to compare against (default: "main")

**Process:**
1. **Scan Commits:**
   - `git log base..branch --pretty=format:"%h %s"`
   - Extract commit messages
   - Group by type (feat, fix, refactor, docs, test)
2. **Analyze Code Changes:**
   - `git diff base..branch --stat`
   - Files added/modified/deleted
   - Lines of code changed
3. **Extract Features:**
   - Parse commit messages for features
   - Detect new classes/functions (AST diff)
   - Identify new tests added
4. **Check Acceptance Criteria:**
   - Load from task cards (`.claude/tasks/`)
   - Mark completed vs pending
5. **Identify Limitations:**
   - TODO comments in code
   - Deferred tasks (from commits mentioning "later", "TODO")
6. **Generate Document**

**Outputs:**
File: `PHASE_3_IMPLEMENTATION.md`
```markdown
# Phase 3: Memory System - Implementation Complete

**Status:** Complete (95%)
**Duration:** Jan 10 - Jan 25, 2026
**Commits:** 42
**Files Changed:** 18 (+3400, -820 lines)

## Features Implemented

### 1. Episodic Memory
- Stores last 1000 events with timestamps
- Query by time range, entity, or action type
- LRU eviction when capacity reached
- **Files:** `EpisodicMemory.java`, `MemoryEvent.java`
- **Tests:** 15 unit tests, 95% coverage

### 2. Semantic Memory (Partial)
- Fact extraction from episodic events (complete)
- Relationship graph (complete)
- Consolidation logic (deferred to Phase 4)
- **Files:** `SemanticMemory.java`, `FactExtractor.java`
- **Tests:** 8 unit tests, 70% coverage

### 3. Memory Query API
- Natural language queries via LLM
- Structured queries for performance
- Batch queries for efficiency
- **Files:** `MemoryQueryEngine.java`
- **Tests:** 12 unit tests

## Acceptance Criteria Status

- [x] Episodic memory stores 1000 events
- [x] Events queryable in <50ms
- [x] Semantic facts extracted automatically
- [ ] Memory consolidation every 100 ticks (deferred)
- [x] Unit tests cover core functionality

## Known Limitations

1. **Consolidation:** Semantic memory consolidation deferred to Phase 4
2. **Performance:** Query performance degrades with >5000 facts (needs indexing)
3. **Persistence:** In-memory only, no disk serialization yet

## Next Steps

### Phase 4: Learning & Adaptation
- Complete semantic memory consolidation
- Add memory persistence
- Optimize query performance (indexing)
- Implement memory-based learning

## Statistics

- **Commits:** 42 (35 feat, 5 fix, 2 refactor)
- **Files:** 18 changed (+3400, -820 lines)
- **Tests:** 35 added (88% pass rate)
- **Coverage:** 85% overall

---

*Auto-generated by Phase Completion Doc Generator on 2026-01-25*
```

**Success Criteria:**
- Generation time: <60 seconds per phase
- Accuracy: 95%+ correct feature extraction
- Completeness: All major changes documented

---

## Implementation Priority

**Week 1-2:** Agents 1-3 (Foundation)
- Session Resume Agent
- Task Card Generator
- CLAUDE.md Generator

**Week 3-4:** Agents 4-5 (Quality)
- Documentation Sync Agent
- Voice Validator

**Week 5-6:** Agents 6-7 (Workflow)
- Compilation Generator
- Phase Completion Doc Generator

---

## Technology Stack for Agents

**Core:**
- Python 3.11+ (async/await support)
- Click (CLI framework)
- Rich (beautiful terminal output)

**File Processing:**
- tree-sitter (AST parsing)
- pygit2 (Git operations)
- ruamel.yaml (YAML with comments)

**NLP/Analysis:**
- spaCy (NLP pipeline)
- textstat (readability metrics)
- OpenAI API (for complex analysis)

**Storage:**
- JSONL (event logs)
- SQLite (optional, for complex queries)

---

## Configuration Format

Each agent uses `.claude/agents/[agent-name].json`:
```json
{
  "enabled": true,
  "version": "1.0.0",
  "config": {
    "lookback_commits": 10,
    "priority_threshold": "P1"
  },
  "hooks": {
    "pre_commit": false,
    "post_commit": true,
    "manual": true
  },
  "overrides": {
    "ignored_patterns": ["*.tmp", "node_modules/"]
  }
}
```

---

*These specifications are ready for implementation. Each agent has clear inputs, processes, outputs, and success criteria.*
