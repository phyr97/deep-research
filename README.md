# Deep Research

A modular [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin for deep research across web, codebase, and knowledge domains. Uses Sonnet for analysts and scrapers, Opus for orchestration and synthesis.

## Features

- Multi-mode research: web, codebase, knowledge synthesis, or mixed
- Auto-scaling: 2-4 analysts based on topic complexity
- Depth-per-question: orchestrator assigns shallow/standard/deep per sub-question so core questions get more thorough coverage
- Iterative scraping: scrapers follow promising links and analysts retry with rephrased queries when results are thin
- Source verification: every finding must link to a URL or file path, enforced by a stop hook
- Few-shot prompted agents: agents follow concrete output examples instead of rule lists for more consistent results
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
Orchestrator (Opus)
  │
  ├── Analyst 1 (Sonnet) ──→ spawns 1-6 scrapers (Sonnet), retries if thin
  ├── Analyst 2 (Sonnet) ──→ spawns 1-6 scrapers (Sonnet), retries if thin
  ├── Self-check ──→ reviews coverage, spawns follow-up analysts if needed
  └── Synthesize ──→ merge findings by theme, list source URLs, write metrics
```

Each tier only sees the output of the tier below (analysts see scraper output, orchestrator sees analyst summaries). Raw scraper data never reaches the orchestrator.

The orchestrator assigns a depth level (shallow/standard/deep) per sub-question. Analysts pass this to their web scrapers, which adjust search count and link-following accordingly.

### Research modes

- Web: external information via WebSearch/WebFetch (depth-controlled)
- Codebase: local code analysis via Read/Glob/Grep
- Knowledge: Opus synthesizes directly from training data (no analyst dispatch)
- Mixed: analysts spawn both web and codebase scrapers

## Enforcement

Agent compliance is enforced through three mechanisms:

1. Few-shot examples in agent prompts show the exact expected output format including source URLs
2. A stop hook (`check-sources.sh`) blocks completion if a research output is missing a Sources section with URLs
3. A second stop hook (`save-metrics.sh`) extracts metrics from the output for tracking

## Plugin structure

```
deep-research/
  .claude-plugin/
    plugin.json                              # Plugin manifest
  skills/
    deep-research/
      SKILL.md                               # Orchestrator skill
      references/                            # Output format, research modes, error handling
  commands/
    deep-research.md                         # /deep-research slash command
  agents/
    dr-analyst.md                            # Analyst agent (Sonnet)
    dr-scraper-web.md                        # Web scraper agent (Sonnet)
    dr-scraper-codebase.md                   # Codebase scraper agent (Sonnet)
  hooks/
    hooks.json                               # Stop hooks for validation and metrics
  scripts/
    check-sources.sh                         # Blocks completion if Sources section missing
    save-metrics.sh                          # Extracts metrics from output to jsonl
```

## License

MIT
