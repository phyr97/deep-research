# Deep Research

A modular [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin for deep research across web, codebase, and knowledge domains. Uses a multi-level model routing strategy (Haiku, Sonnet, Opus) for cost-efficient, high-quality results.

## Features

- Multi-mode research: web, codebase, knowledge synthesis, or mixed
- Auto-scaling: 2-4 analysts based on topic complexity, no manual tier selection
- Self-check: LLM-as-Judge validates synthesis before export, with optional follow-up round
- Metrics tracking: every run appends to ~/.claude/deep-research/metrics.jsonl
- Automatic export: every research auto-saves to `~/.claude/deep-research/`
- Follow-up support: continue previous research with `--follow-up`
- Dynamic MCP detection: auto-discovers and uses available MCP servers (Tidewave, Context7, etc.)
- Safe by design: agents only use read-only tools, validated against an allowlist

## Installation

### Via marketplace

```bash
claude plugin marketplace add phyr97/phyr97-marketplace
claude plugin install deep-research@phyr97
```

### Manual (for development)

```bash
# Use the plugin from a local directory for one session
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

These are all read-only tools. If you prefer not to allow them globally, the plugin will still work in most cases via the `bypassPermissions` frontmatter, but some runs may fail with permission errors.

## Usage

```bash
# Basic research (auto-scales based on complexity)
/deep-research "Caching strategies for Phoenix applications"

# Force a specific mode
/deep-research --mode codebase "Map all GenServer processes in this project"

# Follow up on previous research
/deep-research --follow-up 2026-02-22-caching-strategien "Go deeper into Redis vs ETS"
```

## Architecture

```
Orchestrator (Opus)
  │
  ├── Analyst 1 (Sonnet) ──→ spawns Scraper 1a (Haiku/web), Scraper 1b (Sonnet/codebase)
  │     └── returns: 500 words max, sources tagged by type
  │
  ├── Analyst 2 (Sonnet) ──→ spawns Scraper 2a (Haiku/web), Scraper 2b (Haiku/web)
  │     └── returns: 500 words max, sources tagged by type
  │
  ├── Self-Check (Opus) ──→ validates synthesis, optionally spawns 1 follow-up analyst
  │
  └── Orchestrator synthesizes, exports, writes metrics
```

Key design decisions:

- Analysts own their scrapers: the orchestrator only sees compact analyst summaries (max 500 words each), never raw scraper data. This protects the orchestrator's context window.
- Orchestrator does synthesis: no separate synthesizer agent needed since the orchestrator already runs on Opus.
- Specialized scrapers: web scrapers (Haiku) handle web lookups, codebase scrapers (Sonnet) handle code navigation.
- Self-check before export: catches gaps and missing perspectives before the final report.

### Research modes

- Web: external information via WebSearch/WebFetch (Haiku scrapers)
- Codebase: local code analysis via Read/Glob/Grep + optional Tidewave/Context7 (Sonnet scrapers)
- Knowledge: Opus synthesizes directly from training data, optional web fact-checking (no analyst dispatch)
- Mixed: analysts spawn both web and codebase scrapers for direct comparison

## Output

Results are exported to `~/.claude/deep-research/YYYY-MM-DD-<topic-slug>.md` and presented interactively in chat. Every export starts with a Kernpunkte (Key Points) section for quick orientation.

Metrics are collected automatically via a `Stop` hook that extracts metrics from the orchestrator's output and appends them to `~/.claude/deep-research/metrics.jsonl`. This is deterministic and cannot be skipped by the LLM.

## MCP tools

Research agents use `bypassPermissions` since they only use read-only tools. Known MCP tools (Tidewave, Context7) are detected by checking if `mcp__tidewave__*` or `mcp__context7__*` tools are available in the session. No dynamic discovery or allowlist matching needed.

## Plugin structure

```
deep-research/
  .claude-plugin/
    plugin.json                              # Plugin manifest
  skills/
    deep-research/
      SKILL.md                               # Orchestrator skill
  commands/
    deep-research.md                         # /deep-research slash command
  agents/
    dr-analyst.md                            # Analyst agent (Sonnet)
    dr-scraper-web.md                        # Web scraper agent (Haiku)
    dr-scraper-codebase.md                   # Codebase scraper agent (Sonnet)
  hooks/
    hooks.json                               # Stop hook for metrics collection
  scripts/
    save-metrics.sh                          # Extracts metrics from output, writes to jsonl
  docs/
    video-skill-best-practices.md            # Skill design patterns reference
```

## License

MIT
