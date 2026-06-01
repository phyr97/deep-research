# Investigation brief: deep-research token blow-up (Workflow path vs. Skill path)

> Temporary handoff document. Created 2026-06-01. Delete after the investigation is
> resolved and any findings/fixes are merged into the plugin or its docs.

## How to use this file

Paste this into a fresh Claude Code session opened in this repo
(`/Users/mats/projects/private/plugins/deep-research`). It is self-contained: a new
session has no memory of the run that produced it. Goal of the new session: confirm the
diagnosis, find the root cause of why the Workflow path ran instead of the Skill path,
and decide what the plugin can do defensively.

## TL;DR

A single `/deep-research` invocation on a simple consumer-internet question consumed
**~3.36M tokens across 103 subagents** and then **crashed without producing output**.
The expensive run did **not** come from this plugin's code. The plugin is designed as a
Skill that spawns `Agent(subagent_type: "deep-research:dr-scraper-web", model: "sonnet")`
with a budget of ~12-15 scrapers and a user-facing plan gate. What actually ran was the
generic Claude Code **`Workflow` mechanism** with a fan-out of 5 searchers + 21 extractors
+ 75 adversarial verifiers (3 votes/claim) + 1 synthesis, using forced `StructuredOutput`.
None of `Workflow()`, `StructuredOutput`, or 3-vote verification exists anywhere in this
repo. So the central question is: **why did the command run as a Workflow instead of the
Skill the command file points to?**

## What is confirmed (from the failing run, 2026-06-01)

- Claude Code version: **2.1.159**.
- Installed plugin: **deep-research@phyr97 v2.3.0** (matches this repo's
  `.claude-plugin/plugin.json`, commit `c345419` "Bump to 2.3.0", 2026-05-09).
- Marketplace `phyr97` has **autoUpdate enabled** (last updated 2026-05-26).
- The run executed via the **Workflow tool**, not the Skill. Evidence:
  - Subagent transcripts are under
    `.../subagents/workflows/wf_4cb78e95-550/` and their meta is
    `{"agentType":"workflow-subagent"}` — NOT `deep-research:dr-scraper-web`.
  - Agents were forced to call a `StructuredOutput` tool (80 calls). This repo never
    references `StructuredOutput`.
  - Fan-out observed: 1 scope/decompose, 5 web searchers (1 per angle), 21 source
    extractors, 75 adversarial verifiers (3 voters × 25 claims), 1 synthesis.
- Failure mode: `agent({schema}): subagent completed without calling StructuredOutput
  (after 2 in-conversation nudges)`. Several parallel stages failed this way.
- The synthesis agent received all 10 verified claims but then hit a **session token
  limit ("resets 12pm Europe/Berlin")** and never emitted the final report.
- Usage from the task notification: `agent_count=103`, `subagent_tokens=3,364,993`,
  `tool_uses=388`, `duration_ms=489,746` (~8.2 min).
- Transcript directory (still on disk at time of writing):
  `/Users/mats/.claude/projects/-Users-mats-projects-sandbox/5b0f6eaf-a8f9-44ff-9920-cf8e874a8a88/subagents/workflows/wf_4cb78e95-550/`
- Generated workflow script (auto-created by the run, not by this repo):
  `/Users/mats/.claude/projects/-Users-mats-projects-sandbox/5b0f6eaf-a8f9-44ff-9920-cf8e874a8a88/workflows/scripts/deep-research-wf_4cb78e95-550.js`

## Core discrepancy: what the plugin defines vs. what ran

| Aspect | Plugin v2.3.0 (this repo) | What actually ran |
|---|---|---|
| Entry | `commands/deep-research.md`: "Invoke the `deep-research:deep-research` skill" | `Workflow({ name: "deep-research", args })` |
| Executor | Skill in main context | Background Workflow engine |
| Subagent type | `deep-research:dr-scraper-web` / `-codebase` | `workflow-subagent` |
| Model control | scrapers forced to `model: "sonnet"` | no sonnet override visible |
| Fan-out budget | ~12 sweet spot, ~15 ceiling | 103 agents |
| Verification | none / no analyst layer | 3-vote adversarial, 75 verifier agents |
| Structured output | not used | forced `StructuredOutput` |
| User gate | plan + dispatch-budget shown "before any token is spent" | none; ran straight through in background |

Conclusion: the costly behavior was injected from outside the plugin. The plugin's own
design is comparatively cheap and has a spend gate. The plugin cannot have "caused" the
103-agent fan-out from its current code, because that code path does not exist here.

## Hypotheses to verify (NOT yet confirmed)

1. **Harness wraps slash-command prompts into Workflows.** CC 2.1.159 may route certain
   plugin commands through the Workflow engine instead of the Skill, especially when the
   command description reads like "research / fan-out". The invocation string the model
   received was literally `Workflow({ name: "deep-research", ... })`, which contradicts
   the command file. This is the leading hypothesis.
2. **Name collision.** A built-in or harness-registered Workflow named `deep-research`
   may shadow the plugin command of the same name.
3. **autoUpdate drift.** Something changed between the last "cheap" run and this one —
   either a plugin bump or a CC update. The plugin bump to 2.3.0 was 2026-05-09; the
   marketplace last synced 2026-05-26. Worth diffing.

What is explicitly NOT yet known: whether a CC update is the trigger. The CC 2.1.159
changelog was not read. Do not assert the cause without checking it.

## Investigation steps for the new session

1. Reproduce minimally: run `/deep-research "tiny test question"` and observe whether a
   Skill (`deep-research:dr-scraper-web` subagents) or a Workflow (`workflow-subagent`,
   StructuredOutput) starts. Watch `/workflows`. **Set a hard stop / kill early** to avoid
   another blow-up.
2. Read the CC 2.1.159 release notes / changelog for any change to how slash commands or
   plugin commands dispatch (Skill vs Workflow routing). Check the `check-cc-update` skill
   in this repo — it may already track this.
3. Inspect the generated workflow script (path above) to see the exact fan-out the harness
   built, and compare against `skills/deep-research/SKILL.md` dispatch rules.
4. Confirm whether `commands/deep-research.md` is being honored at all, or overridden.
5. Check whether the `Stop` hook (`scripts/save-metrics.sh`) and the `Agent` auto-approve
   hook even fire on the Workflow path (the auto-approve matcher keys on
   `subagent_type == deep-research:*`, which a `workflow-subagent` would not match).

## Candidate fixes / improvements (decide after diagnosis)

- If the harness auto-wraps the command: make `commands/deep-research.md` explicit that it
  must run as the Skill, or rename/structure the command so it is not captured by Workflow
  routing. Verify against CC docs first.
- Add a guard in the Skill that detects it is NOT running on the intended path and aborts
  with a clear message instead of letting a 100-agent Workflow proceed.
- Independent of the Workflow issue, tighten the Skill's own spend gate: the SKILL.md
  already promises a plan + dispatch-budget before spending; confirm that gate is
  unmissable and that scrapers really inherit `model: "sonnet"`.
- Consider a config flag / env to cap total agents and require explicit opt-in above a
  threshold (e.g. >15 subagents).
- The auto-approve hook only covers `deep-research:*` subagents. If the Workflow path is
  intended in some cases, the hook will never gate it; if it is not intended, that is fine.

## Open questions

- Is the Workflow path ever intended for this plugin, or is it always a misroute?
- Did a specific CC version introduce command→Workflow routing? Which one?
- Was the pre-incident "cheap" behavior the Skill path, and did it change due to a CC
  update or the 2.3.0 bump? A git diff of this repo around 2.3.0 plus the CC changelog
  should answer this.
- Should the plugin pin a known-good behavior by disabling marketplace autoUpdate in the
  user's setup, or is a code-level guard preferable?

## Context that triggered this

User ran `/deep-research` for a low-stakes question ("Starlink alternatives for home
internet in Germany"). The Workflow crashed; the actual answer was later produced with
five targeted `WebFetch` calls in the main session. The mismatch between effort (~3.36M
tokens, 103 agents) and task size is what prompted this investigation.
