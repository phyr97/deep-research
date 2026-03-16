# Deep Research

A modular [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin for deep research across web, codebase, and knowledge domains. Uses Sonnet for sub-agents and lookups, Opus for orchestration and synthesis.

## Features

- Multi-mode research: web, codebase, knowledge synthesis, or mixed
- Auto-scaling: 2-4 sub-agents based on topic complexity
- Depth-per-question: orchestrator assigns shallow/standard/deep per sub-question
- Iterative lookups: web lookups follow promising links, sub-agents retry with rephrased queries
- Source verification: every finding must link to a URL or file path
- Dual-channel instructions: agent system prompts (body) and orchestrator prompt parameter reinforce the same output format
- Metrics tracking: every run appends to ~/.claude/deep-research/metrics.jsonl
- Optional report export: save research as markdown file on request

## Installation

### Via marketplace

```bash
claude plugin marketplace add phyr97/phyr97-marketplace
claude plugin install deep-research@phyr97
```

### Manual (for development)

```bash
claude --plugin-dir /path/to/deep-research
```

### Recommended: agent permissions

Claude Code has known issues with `bypassPermissions` for subagents (see [#29110](https://github.com/anthropics/claude-code/issues/29110), [#24073](https://github.com/anthropics/claude-code/issues/24073)). To ensure research agents can reliably access their tools, add these entries to your global `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch",
      "Glob",
      "Grep",
      "Read"
    ]
  }
}
```

## Usage

```bash
# Basic research (auto-scales based on complexity)
/deep-research "Caching strategies for Phoenix applications"

# Force a specific mode
/deep-research --mode codebase "Map all GenServer processes in this project"
```

## Architecture

```
Orchestrator (Opus, Skill)
  │
  ├── Sub-agent 1 (Sonnet, dr-a1) ──→ spawns 1-6 lookups (dr-sw, dr-sc)
  ├── Sub-agent 2 (Sonnet, dr-a1) ──→ spawns 1-6 lookups, retries if thin
  ├── Self-check ──→ reviews coverage, spawns follow-up sub-agents if needed
  └── Synthesize ──→ merge findings by theme, list source URLs, write metrics
```

Agent .md files contain both frontmatter (model, tools, permissions) and a system prompt with output format examples. The orchestrator also passes the same key instructions via the `prompt` parameter when spawning agents, reinforcing the output format through both channels.

### Research modes

- Web: external information via WebSearch/WebFetch (depth-controlled)
- Codebase: local code analysis via Read/Glob/Grep
- Knowledge: Opus synthesizes directly from training data (no sub-agent dispatch)
- Mixed: sub-agents spawn both web and codebase lookups

## Plugin structure

```
deep-research/
  .claude-plugin/
    plugin.json                              # Plugin manifest
  skills/
    deep-research/
      SKILL.md                               # Orchestrator (contains all agent prompts)
      references/                            # Output format, research modes, error handling
  commands/
    deep-research.md                         # /deep-research slash command
  agents/
    dr-analyst.md                            # Research sub-agent (Sonnet)
    dr-scraper-web.md                        # Web lookup sub-agent (Sonnet)
    dr-scraper-codebase.md                   # Codebase lookup sub-agent (Sonnet)
  hooks/
    hooks.json                               # Stop hook for metrics collection
  scripts/
    save-metrics.sh                          # Extracts metrics from output to jsonl
```

## License

MIT
