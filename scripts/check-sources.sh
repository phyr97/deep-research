#!/bin/bash
# Checks if the orchestrator's final output contains a Sources section with URLs.
# Called by the Stop hook. Blocks completion (exit 2) if sources are missing.

if ! command -v python3 &>/dev/null; then
    exit 0
fi

result=$(python3 -c "
import sys, json, re
try:
    data = json.load(sys.stdin)
    msg = data.get('last_assistant_message', '')
    # Only check if this looks like a deep-research output (has METRICS comment)
    if '<!-- METRICS:' not in msg:
        print('skip')
        sys.exit(0)
    # Check for Sources section with at least one URL
    has_sources = bool(re.search(r'## Sources\b', msg))
    has_urls = bool(re.search(r'https?://', msg[msg.find('## Sources'):] if has_sources else ''))
    if has_sources and has_urls:
        print('ok')
    else:
        print('missing')
except Exception:
    print('skip')
" 2>/dev/null)

if [ "$result" = "missing" ]; then
    echo "Your research output is missing a Sources section with URLs. Add a '## Sources' section listing the URLs from analyst reports before finishing." >&2
    exit 2
fi

exit 0
