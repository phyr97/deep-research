# Deep Research

A modular [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin for deep research across web, codebase, and knowledge domains. Uses Sonnet for analysts and scrapers, Opus for orchestration and synthesis.

## Features

- Multi-mode research: web, codebase, knowledge synthesis, or mixed
- Auto-scaling: 2-4 analysts based on topic complexity, no manual tier selection
- Depth-per-question: orchestrator assigns shallow/standard/deep per sub-question so core questions get more thorough coverage
- Iterative scraping: scrapers follow promising links and analysts retry with rephrased queries when results are thin
- Self-check with up to 2 follow-up rounds to fill gaps
- Metrics tracking: every run appends to ~/.claude/deep-research/metrics.jsonl
- Follow-up support: continue previous research with `--follow-up`
- Dynamic MCP detection: auto-discovers and uses available MCP servers (Tidewave, Context7, etc.)
- Safe by design: agents only use read-only tools

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
  ├── Analyst 1 (Sonnet) ──→ spawns up to 6 scrapers (Sonnet/web, Sonnet/codebase)
  │     └── returns: 1000 words max, sources tagged by type
  │
  ├── Analyst 2 (Sonnet) ──→ spawns up to 6 scrapers, retries if results are thin
  │     └── returns: 1000 words max, sources tagged by type
  │
  ├── Self-Check (Opus) ──→ validates synthesis, up to 2 follow-up rounds
  │
  └── Orchestrator synthesizes, exports, writes metrics
```

Key design decisions:

- Analysts own their scrapers: the orchestrator only sees compact analyst summaries (max 1000 words each), never raw scraper data. This protects the orchestrator's context window.
- Orchestrator does synthesis: no separate synthesizer agent needed since the orchestrator already runs on Opus.
- Depth-per-question: the orchestrator assigns shallow/standard/deep to each sub-question. Scrapers adjust search count and link-following accordingly.
- Analyst retry: when scraper results are thin, analysts spawn additional scrapers with rephrased queries before giving up.
- Self-check before export: catches gaps and missing perspectives, with up to 2 follow-up rounds.

### Research modes

- Web: external information via WebSearch/WebFetch (Sonnet scrapers, depth-controlled)
- Codebase: local code analysis via Read/Glob/Grep + optional Tidewave/Context7 (Sonnet scrapers)
- Knowledge: Opus synthesizes directly from training data, optional web fact-checking (no analyst dispatch)
- Mixed: analysts spawn both web and codebase scrapers for direct comparison

## Output

Results are presented interactively in chat with a Kernpunkte (Key Points) section for quick orientation, followed by detailed findings organized by theme.

Metrics are collected automatically via a `Stop` hook that extracts metrics from the orchestrator's output and appends them to `~/.claude/deep-research/metrics.jsonl`.

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
    hooks.json                               # Stop hook for metrics collection
  scripts/
    save-metrics.sh                          # Extracts metrics from output, writes to jsonl
```

## License

MIT
