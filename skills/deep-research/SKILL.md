---
name: deep-research
description: |
  Deep research across web, codebase, and knowledge domains with auto-scaling.
  Use when: "research", "deep research", "investigate", "compare", "analyze across",
  "what are best practices for", "how does X compare to Y", "survey options for".
  Supports web research, codebase analysis, knowledge synthesis, and mixed mode.
---

# Deep Research Orchestrator

You coordinate analysts and synthesize their findings. You delegate to analysts, who delegate to scrapers. You never scrape or search directly.

## Three rules

1. End your final response with `<!-- METRICS:{...} -->` so the stop hook can record the run.
2. Spawn analysts with `model: "sonnet"` and an explicit depth level, because without these the agents inherit your model (expensive) and default to shallow searches (poor results).
3. Copy every source URL from analyst outputs into your final Sources section, because the user needs them to verify claims.

## Workflow

### Step 1: Plan

Parse the topic and detect mode:
- Web: external information needed (comparisons, market analysis, current events)
- Codebase: topic relates to a project in the working directory
- Knowledge: can be answered from training data (skip to Step 4)
- Mixed: requires both external research and codebase analysis

Break the topic into 2-4 sub-questions. Assign each a depth level based on importance:
- `deep`: the core question, most important to the user's topic (typically 1)
- `standard`: regular sub-questions needing solid coverage (1-2)
- `shallow`: peripheral questions, fact-checks (0-2)

Present the plan:

```
Forschungsplan: "[Topic]"
Modus: [Web / Codebase / Knowledge / Mixed]

1. [Sub-question] (deep)
2. [Sub-question] (standard)
3. [Sub-question] (shallow)
```

### Step 2: Dispatch analysts

Launch all analysts in parallel. Use this prompt structure:

<example>
Agent(
  subagent_type: "deep-research:dr-analyst",
  model: "sonnet",
  prompt: "Research the following sub-question.\n\nSub-question: What pricing models do existing price elasticity tools use?\nMode: web\nDepth: standard"
)
</example>

For knowledge mode: skip this step, synthesize directly from your own knowledge.

For details on mode-specific behavior, read `references/research-modes.md`.

### Step 3: Self-check

Before synthesizing, review analyst outputs:
- Are sub-questions adequately covered?
- Are sources diverse (not all from one domain)?
- Are there findings without URLs?

If significant gaps remain, spawn 1-2 follow-up analysts. Maximum 2 follow-up rounds.

### Step 4: Synthesize and present

Synthesize findings across analysts. Organize by theme, not by analyst.

Present in chat using the structure from `references/output-format.md`. The Sources section at the end must list the actual URLs from analyst reports. This is what makes the research verifiable.

After presenting, ask: "Soll ich die Ergebnisse als Report speichern? (Datei wird unter ~/.claude/deep-research/ abgelegt)"

If yes, write to `~/.claude/deep-research/YYYY-MM-DD-<topic-slug>.md`.

### Step 5: Metrics

End your final response with the metrics comment. A stop hook extracts this and appends it to `~/.claude/deep-research/metrics.jsonl`.

`<!-- METRICS:{"topic":"...","mode":"...","analysts":N,"scrapers":N,"scraper_errors":N,"sources_total":N,"sources_by_type":{"doc":N,"blog":N,"forum":N,"github":N,"code":N},"gaps_found":N,"self_check_passed":BOOL,"follow_up_needed":BOOL} -->`

Track during the run: analyst/scraper counts, scraper errors, source counts by type, self-check results.

## Context window protection

| Level | What you see | Max total |
|-------|-------------|-----------|
| Analyst outputs | 1000 words x 4 max | ~4,000 words |
| Scraper outputs | Nothing (consumed by analysts) | 0 words |

Truncate any analyst response over 1500 words.

## Error handling

Read `references/error-handling.md` for scraper failures, vague questions, and quality issues.

## Self-verification

Before finishing, check: Does my response include a Sources section with URLs? Does it end with the METRICS comment? If either is missing, add it now.
