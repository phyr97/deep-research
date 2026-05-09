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

The plugin includes a `PreToolUse` hook that auto-approves `Agent(deep-research:dr-scraper-*)` spawns from the orchestrator, so most users don't need any additional setup.

If your environment disables plugin hooks or you want explicit permissions in `settings.json`, allow the following:

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch",
      "Glob",
      "Grep",
      "Read",
      "Agent(deep-research:dr-scraper-web)",
      "Agent(deep-research:dr-scraper-codebase)"
    ]
  }
}
```

Background: Claude Code has known issues with `bypassPermissions` for subagents (see [#29110](https://github.com/anthropics/claude-code/issues/29110), [#24073](https://github.com/anthropics/claude-code/issues/24073)). The flat orchestrator → scraper architecture in v2.2.0 sidesteps these issues by avoiding nested `Agent` calls entirely.

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
  ├── For each sub-question:
  │     ├── dr-scraper-web (Sonnet)   ──→ writes facts file
  │     ├── dr-scraper-web (Sonnet)   ──→ writes facts file
  │     └── dr-scraper-codebase (S.)  ──→ writes facts file
  │
  ├── Self-check ──→ reviews coverage, spawns follow-up scrapers if thin
  └── Synthesize ──→ merge findings by theme, list source URLs, write metrics
```

Flat dispatch (orchestrator → scrapers, one hop). The previous `dr-analyst` middle layer was removed in v2.2.0 because nested `Agent` calls do not reliably propagate tool access through Claude Code's permission model (see [#29110](https://github.com/anthropics/claude-code/issues/29110)).

Before scrapers are dispatched, the orchestrator presents a plan with the dispatch budget (count + per-sub-question depth, rationale, and angles) and asks for approval via `AskUserQuestion`. The user can approve, adjust (sub-question, depth, scraper count, mode, angles), or cancel. The gate is skipped only when the topic contains the literal `--yes` / `--no-confirm` token or when the budget is a single scraper.

Agent .md files contain frontmatter (model, tools, permissions) plus the system prompt that defines output format and process. The orchestrator passes only the question, depth, constraints, and output path via the spawn `prompt` parameter — the agent body provides format and rules.

A `PreToolUse` hook auto-approves `Agent(deep-research:...)` spawns from the orchestrator so users don't need to add Agent permissions manually.

### Research modes

- Web: external information via dr-scraper-web (depth-controlled)
- Codebase: local code analysis via dr-scraper-codebase
- Knowledge: orchestrator drafts top claims, then dispatches verification scrapers — no claim ships without a fetched source
- Mixed: orchestrator spawns both web and codebase scrapers per sub-question

## Plugin structure

```
deep-research/
  .claude-plugin/
    plugin.json                              # Plugin manifest
  skills/
    deep-research/
      SKILL.md                               # Orchestrator
      references/                            # Output format, research modes, error handling
  commands/
    deep-research.md                         # /deep-research slash command
  agents/
    dr-scraper-web.md                        # Web scraper (Sonnet)
    dr-scraper-codebase.md                   # Codebase scraper (Sonnet)
  hooks/
    hooks.json                               # PreToolUse auto-approve + Stop metrics
  scripts/
    auto-approve-subagents.sh                # PreToolUse hook
    save-metrics.sh                          # Stop hook
  scripts/
    save-metrics.sh                          # Extracts metrics from output to jsonl
```

## License

MIT
