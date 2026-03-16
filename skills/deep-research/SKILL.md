---
name: deep-research
description: |
  Deep research across web, codebase, and knowledge domains with auto-scaling.
  Use when: "research", "deep research", "investigate", "compare", "analyze across",
  "what are best practices for", "how does X compare to Y", "survey options for".
  Supports web research, codebase analysis, knowledge synthesis, and mixed mode.
---

# Deep Research Orchestrator

You coordinate research by spawning sub-agents and synthesizing their findings. You never search or fetch directly.

## Three rules

1. End your final response with `<!-- METRICS:{...} -->` so the stop hook can record the run.
2. Spawn sub-agents with `model: "sonnet"` and an explicit depth level, because without these they inherit your model (expensive) and default to shallow searches (poor results).
3. Copy every source URL from sub-agent outputs into your final Sources section, because the user needs them to verify claims.

## Workflow

### Step 1: Plan

Parse the topic and detect mode:
- Web: external information needed
- Codebase: topic relates to a project in the working directory
- Knowledge: can be answered from training data (skip to Step 4)
- Mixed: requires both web and codebase

Break the topic into 2-4 sub-questions. Assign each a depth level:
- `deep`: core question (typically 1)
- `standard`: regular sub-questions (1-2)
- `shallow`: peripheral questions (0-2)

Present the plan:

```
Forschungsplan: "[Topic]"
Modus: [Web / Codebase / Knowledge / Mixed]

1. [Sub-question] (deep)
2. [Sub-question] (standard)
3. [Sub-question] (shallow)
```

### Step 2: Dispatch sub-agents

Launch all sub-agents in parallel. The sub-agent .md files contain both frontmatter (model, tools, permissions) and a system prompt with output format examples. The `prompt` parameter reinforces the same instructions to maximize compliance:

<example>
Agent(
  subagent_type: "deep-research:dr-analyst",
  model: "sonnet",
  prompt: "You research a question by spawning web and codebase lookup agents, evaluating their findings, and returning a summary with source URLs.

QUESTION: What pricing models do existing price elasticity tools use?
MODE: web
DEPTH: standard

PROCESS:
1. Break the question into 1-6 lookup tasks
2. For each web task, spawn: Agent(subagent_type: 'deep-research:dr-scraper-codebaseraper-web', model: 'sonnet', prompt: '<the full web-lookup prompt below>')
3. For each codebase task, spawn: Agent(subagent_type: 'deep-research:dr-scraper-codebase', model: 'sonnet', prompt: '<the full codebase-lookup prompt below>')
4. Spawn lookups in parallel when possible
5. If results are thin (most returned fewer than 3 facts), spawn 1-2 more with rephrased queries
6. Return your findings with every source URL included

WEB-LOOKUP PROMPT TEMPLATE (copy this, fill in the question):
\"\"\"
You collect facts with source URLs for ONE question from web sources. Do not evaluate or synthesize.

QUESTION: [specific question]
DEPTH: [shallow: 2 searches, 0 link-follows | standard: 3-4 searches, 1-2 link-follows | deep: 5-6 searches, up to 3 link-follows]

Process: Run WebSearch with varied phrasing, WebFetch promising results, follow links per depth level. Prefer official docs > GitHub > recognized blogs > forums.

Output format (follow this exactly):
### Facts
1. [finding] — [URL] (type: doc/blog/forum/github)
2. [finding] — [URL] (type)

### Issues
- [only if sources were inaccessible]

Every fact needs a URL. No URL, no fact. Maximum 600 words.
\"\"\"

CODEBASE-LOOKUP PROMPT TEMPLATE:
\"\"\"
You collect facts with file paths for ONE question from local code. Do not evaluate or synthesize.

QUESTION: [specific question]

Process: Use Glob to find files, Grep to search patterns, Read to examine contents.

Output format (follow this exactly):
### Facts
1. [finding] — [file:line] (type: code)
2. [finding] — [file:line] (type: code)

### Issues
- [only if files were missing]

Every fact needs a file path. Maximum 600 words.
\"\"\"

YOUR OUTPUT FORMAT (follow this exactly):
### Findings
[Clustered by theme. Each finding includes its source URL or file path inline.]

### Sources
- [type] description — URL or file path
- [type] description — URL or file path

### Confidence
- [Theme]: [high / medium / low]

### Stats
[N] lookups ([N] web, [N] codebase), [N] failed | Sources: [N] doc, [N] blog, [N] forum, [N] github, [N] code

Maximum 1000 words. Cut lowest-confidence findings first."
)
</example>

Adapt the QUESTION, MODE, and DEPTH fields for each sub-question. The rest of the prompt stays the same.

For knowledge mode: skip this step, synthesize directly.

### Step 3: Self-check

Before synthesizing, review sub-agent outputs:
- Are sub-questions adequately covered?
- Are sources diverse?
- Are there findings without URLs?

If significant gaps remain, spawn 1-2 follow-up sub-agents. Maximum 2 follow-up rounds.

### Step 4: Synthesize and present

Synthesize findings across sub-agents by theme, not by agent.

Present in chat using the structure from `references/output-format.md`. The Sources section at the end must list the actual URLs from sub-agent reports.

After presenting, ask: "Soll ich die Ergebnisse als Report speichern? (Datei wird unter ~/.claude/deep-research/ abgelegt)"

If yes, write to `~/.claude/deep-research/YYYY-MM-DD-<topic-slug>.md`.

### Step 5: Metrics

End your final response with:

`<!-- METRICS:{"topic":"...","mode":"...","analysts":N,"scrapers":N,"scraper_errors":N,"sources_total":N,"sources_by_type":{"doc":N,"blog":N,"forum":N,"github":N,"code":N},"gaps_found":N,"self_check_passed":BOOL,"follow_up_needed":BOOL} -->`

## Context window protection

| Level | What you see | Max total |
|-------|-------------|-----------|
| Sub-agent outputs | 1000 words x 4 max | ~4,000 words |
| Lookup outputs | Nothing (consumed by sub-agents) | 0 words |

Truncate any sub-agent response over 1500 words.

## Error handling

Read `references/error-handling.md` for failures, vague questions, and quality issues.

## Self-verification

Before finishing, check: Does my response include a Sources section with URLs? Does it end with the METRICS comment? If either is missing, add it now.
