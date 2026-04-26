#!/bin/bash
# Records a failed research run when the Stop hook didn't fire (e.g. API errors).
# Called by the StopFailure hook. Always writes a minimal failure entry.

METRICS_FILE="$HOME/.claude/deep-research/metrics.jsonl"

if ! command -v python3 &>/dev/null; then
    exit 0
fi

entry=$(python3 -c "
import sys, json, datetime
try:
    data = json.load(sys.stdin)
except Exception:
    data = {}
out = {
    'status': 'failed',
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
    'reason': data.get('error') or data.get('reason') or 'unknown',
}
print(json.dumps(out, ensure_ascii=False))
" 2>/dev/null)

[ -z "$entry" ] && exit 0

mkdir -p "$(dirname "$METRICS_FILE")"
echo "$entry" >> "$METRICS_FILE"
