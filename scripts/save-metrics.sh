#!/bin/bash
# Extracts METRICS JSON from the Stop hook payload and appends to metrics.jsonl.
# Called by the Stop hook after every response. Only acts if <!-- METRICS:{...} --> is present.

METRICS_FILE="$HOME/.claude/deep-research/metrics.jsonl"

if ! command -v python3 &>/dev/null; then
    exit 0
fi

# Read hook payload from stdin, parse JSON properly, extract metrics
metrics=$(python3 -c "
import sys, json, re
try:
    data = json.load(sys.stdin)
    msg = data.get('last_assistant_message', '')
    match = re.search(r'<!-- METRICS:(\{.*?\}) -->', msg, re.DOTALL)
    if match:
        parsed = json.loads(match.group(1))
        print(json.dumps(parsed, ensure_ascii=False))
except Exception:
    pass
" 2>/dev/null)

if [ -z "$metrics" ]; then
    exit 0
fi

mkdir -p "$(dirname "$METRICS_FILE")"
echo "$metrics" >> "$METRICS_FILE"
