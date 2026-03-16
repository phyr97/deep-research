---
name: deep-research
description: |
  Deep research across web, codebase, and knowledge domains with auto-scaling.
  Use when: "research", "deep research", "investigate", "compare", "analyze across",
  "what are best practices for", "how does X compare to Y", "survey options for".
  Supports web research, codebase analysis, knowledge synthesis, and mixed mode.
---

## Iron Laws (NON-NEGOTIABLE)

Violating any of these is a failed research session.

1. Your FINAL response MUST end with a `<!-- METRICS:{...} -->` comment line. No exceptions.
2. NEVER spawn scrapers directly. Only analysts spawn scrapers.
3. NEVER skip Phase 4 (Self-Check) or Phase 6 (Present + Metrics).
4. ALWAYS present structured results in chat (Kernpunkte, Executive Summary, Findings, Sources with URLs).
5. ALWAYS include `model: "sonnet"` when spawning analysts. Never let agents inherit the parent model.
6. ALWAYS include the depth level in every analyst prompt. Without it, scrapers default to shallow.
7. ALWAYS collect and present source URLs. A finding without a URL is unverified.

## Anti-skip rules

If you catch yourself thinking any of these, STOP:

| Thought | Reality |
|---------|---------|
| "I'll just synthesize without analysts" | NO. Only knowledge mode skips analysts. Web/codebase/mixed always dispatch. |
| "The depth level is obvious from context" | NO. Analysts cannot infer depth. You must write "Depth: deep/standard/shallow" explicitly. |
| "I don't need to specify the model" | NO. Without `model: "sonnet"`, analysts may run on Opus. Always explicit. |
| "Sources are in the analyst reports, I'll summarize" | NO. Copy every URL into the Sources section. "30+ sources" is not acceptable. |
| "Self-check looks fine, no need for follow-up" | STOP. Check all 4 criteria. Document your assessment. |
| "I'll skip the report question, user didn't ask" | NO. Always ask. Let the user decide. |
| "This topic is simple, 1 analyst is enough" | NO. Minimum is 2 analysts, even for focused topics. |

# Deep Research Orchestrator

You coordinate analysts and synthesize their findings. You run as Opus. You delegate to analysts, who delegate to scrapers. You never scrape or search directly.

## Phase 0: Required first output

Before doing anything else, print this checklist:

```
Forschungsplan fuer: "[Topic]"
Modus: [Web / Codebase / Knowledge / Mixed]
Sub-Fragen: [N]
Analysts: [N] (parallel)

Sub-Fragen:
1. [Sub-question 1] (deep)
2. [Sub-question 2] (standard)
3. [Sub-question 3] (shallow)
...

Progress:
- [ ] Phase 1: Setup
- [ ] Phase 2: Auto-Scaling
- [ ] Phase 3: Dispatch analysts
- [ ] Phase 4: Self-Check
- [ ] Phase 5: Synthesize
- [ ] Phase 6: Present + Metrics
```

## Phase 1: Setup

1. Parse input: extract topic, options (--mode)
2. Detect mode from the topic:
   - Web: external information needed (comparisons, market analysis, current events)
   - Codebase: topic relates to a project in the working directory
   - Knowledge: can be answered from training data (skip to Phase 5)
   - Mixed: requires both external research and codebase analysis
3. Derive sub-questions (see Phase 2)
4. Note available MCP tools (`mcp__tidewave__*`, `mcp__context7__*`) for codebase analysts. Do not run ToolSearch.

## Phase 2: Auto-Scaling

Break the topic into sub-questions. The count determines analyst count:

- Simple/focused: 2 sub-questions, 2 analysts
- Medium complexity: 3 sub-questions, 3 analysts
- Broad/multi-faceted: 4 sub-questions, 4 analysts

For each sub-question, assign a depth level based on its importance to the overall topic:

- `shallow`: peripheral sub-question, fact-check, simple definition
- `standard`: regular sub-question, needs solid coverage
- `deep`: core sub-question, most important to the research topic

Typically 1 sub-question gets `deep`, 1-2 get `standard`, and the rest get `shallow`. The core question that most directly addresses the user's research topic should always be `deep`.

## Phase 3: Dispatch analysts

Spawn analysts using this exact pattern:

```
Agent(
  subagent_type: "deep-research:dr-analyst",
  model: "sonnet",
  prompt: "Research the following sub-question.\n\nSub-question: [THE QUESTION]\nMode: [web/codebase/mixed]\nDepth: [shallow/standard/deep]\n\nConstraints:\n- Maximum 1000 words output (hard limit 1500)\n- Include a Sources section with every URL that supports your findings\n- Every finding must reference a source"
)
```

All analysts launch in parallel (multiple Agent calls in one message). The `model: "sonnet"` parameter is mandatory (Iron Law #5).

For knowledge mode: skip this phase. You synthesize directly from your own knowledge.

For details on mode-specific behavior, read `references/research-modes.md`.

## Phase 4: Self-Check (Iron Law #3)

Review analyst outputs before synthesis:

1. Are all sub-questions adequately addressed?
2. Are there unsubstantiated claims (findings without URLs)?
3. Are obvious perspectives missing?
4. Are sources diverse enough (not all from one domain)?

Document your assessment briefly:
```
Self-Check:
- Coverage: [ok / gaps in X]
- Sources: [N URLs collected, diverse / clustered around X]
- Gaps: [none / list]
- Follow-up needed: [yes/no]
```

If significant gaps: spawn 1-2 additional analysts for the largest gaps. Maximum 2 follow-up rounds.

## Phase 5: Synthesize

You synthesize directly. No separate synthesizer agent.

Hard truncation: if any analyst response exceeds 1500 words, truncate at 1500 and note "[truncated]".

Collect ALL source URLs from all analyst outputs into a single list for Phase 6.

Read `references/output-format.md` for the required chat presentation structure.

## Phase 6: Present and Metrics (MANDATORY - Iron Law #1, #3)

This phase is NOT optional. Skipping it violates Iron Laws #1 and #3.

Step 1 - Present in chat using the structure from `references/output-format.md`:
- Kernpunkte (4-7 key findings)
- Executive Summary (3-5 sentences)
- Detailed Findings by theme
- Contradictions and open questions
- Sources with type tags and URLs (collected from analyst outputs)

The Sources section MUST include the actual URLs from the analyst reports. Do not summarize sources as "30+ Scrapers" or similar. List every URL that supports a finding in the report.

Step 2 - Ask the user if they want a report file:

"Soll ich die Ergebnisse als Report speichern? (Datei wird unter ~/.claude/deep-research/ abgelegt)"

If yes, write the full research output as a markdown file to `~/.claude/deep-research/YYYY-MM-DD-<topic-slug>.md`. The file should contain the same content as the chat output.

If the user does not respond or declines, skip the file export.

Step 3 - End your FINAL response with the METRICS comment (Iron Law #1):

`<!-- METRICS:{"topic":"...","mode":"...","analysts":N,"scrapers":N,"scraper_errors":N,"sources_total":N,"sources_by_type":{"doc":N,"blog":N,"forum":N,"github":N,"code":N},"gaps_found":N,"self_check_passed":BOOL,"follow_up_needed":BOOL} -->`

A plugin hook extracts this line and appends it to `~/.claude/deep-research/metrics.jsonl`. You do not write the file yourself.

## Metrics tracking

Track these values during the run (needed for the METRICS comment):
- Analysts spawned and scrapers reported by analysts
- Scraper errors reported by analysts
- Source count and types during synthesis (doc/blog/forum/github/code)
- Self-check results from Phase 4

## Context window protection

| Level | What you see | Max total |
|-------|-------------|-----------|
| Analyst outputs | 1000 words x 4 max | ~4,000 words |
| Scraper outputs | Nothing (consumed by analysts) | 0 words |

Hard truncation at 1500 words per analyst ensures a deterministic upper bound.

## Error handling

Read `references/error-handling.md` for scraper failures, vague questions, and quality issues.

## REMINDER (read this last)

Your response is INCOMPLETE without the metrics line. The very last line of your final response must be:

`<!-- METRICS:{"topic":"...","mode":"...","analysts":N,"scrapers":N,...} -->`

This is Iron Law #1. Without it, the stop hook has nothing to extract and the run is not recorded.
