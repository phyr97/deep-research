#!/usr/bin/env bash
# PreToolUse hook: auto-approve Agent calls to deep-research subagents.
#
# Saves the user from having to allow `Agent(deep-research:dr-scraper-web)` and
# `Agent(deep-research:dr-scraper-codebase)` in settings.json manually. Related
# Claude Code permission quirks: https://github.com/anthropics/claude-code/issues/29110.
#
# Hook output schema (PreToolUse permissionDecision) is the form documented in the
# yurukusa workaround comment on that issue (Mar 2026). If Claude Code changes the
# hook contract, update the JSON below — when in doubt, check the current docs at
# https://docs.anthropic.com/en/docs/claude-code/hooks before debugging.
#
# Reads the PreToolUse JSON from stdin. If the tool is `Agent` and the
# subagent_type starts with `deep-research:`, emit allow decision. Otherwise no-op
# (other PreToolUse hooks in the chain still run).
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

if [ "$TOOL_NAME" = "Agent" ] && [[ "$SUBAGENT_TYPE" == deep-research:* ]]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"deep-research subagent auto-approve"}}
EOF
fi

exit 0
