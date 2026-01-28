# .claude/ Directory Template

This template provides a standard structure for AI-assisted development across all projects.

## Directory Structure

```
.claude/
├── README.md                    # This file
├── agents/                      # Agent configurations
│   ├── session-resume.json
│   ├── task-generator.json
│   ├── doc-sync.json
│   └── voice-validator.json
├── memory/                      # Session memory and learnings
│   ├── sessions.jsonl          # Session history
│   ├── patterns.json           # Learned patterns
│   └── tools-used.json         # Tool frequency tracking
├── tasks/                      # Task management
│   ├── current.json            # Active tasks
│   ├── completed.jsonl         # Task history
│   └── blocked.json            # Blocked tasks
└── config.json                 # Project-specific settings
```

## Usage

Copy this template to your project root:

```bash
cp -r .claude-template /path/to/your/project/.claude
cd /path/to/your/project
# Customize .claude/config.json for your project
```

## See Also

- CROSS-PROJECT-LEARNINGS.md - Development patterns and best practices
- AGENT-SPECIFICATIONS.md - Detailed agent specifications
