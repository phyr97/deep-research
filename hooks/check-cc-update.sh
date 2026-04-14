#!/bin/bash
# Checks if Claude Code was updated since the last plugin modernization.
# Fast: only compares version strings. Outputs context for Claude only if mismatch found.

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"

# Prefer CLAUDE_PLUGIN_DATA (persists across plugin updates), fall back to plugin dir
if [ -n "$CLAUDE_PLUGIN_DATA" ]; then
    LOCAL_STATE="$CLAUDE_PLUGIN_DATA/local-state.json"
else
    LOCAL_STATE="$PLUGIN_DIR/.claude-plugin/local-state.json"
fi

# Current CC version
CURRENT_CC=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
[ -z "$CURRENT_CC" ] && exit 0

# Stored CC version from local state
STORED_CC=$(python3 -c "import json; print(json.load(open('$LOCAL_STATE')).get('lastCheckedCCVersion', ''))" 2>/dev/null)
[ "$CURRENT_CC" = "$STORED_CC" ] && exit 0

PLUGIN_NAME=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['name'])" 2>/dev/null)
PLUGIN_VERSION=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])" 2>/dev/null)

cat <<EOF
Plugin-Modernisierung: Neue Claude Code Version $CURRENT_CC erkannt.
Plugin: $PLUGIN_NAME v$PLUGIN_VERSION (zuletzt geprueft gegen CC ${STORED_CC:-noch nie}).

Fuehre folgende Schritte aus bevor du mit der eigentlichen Aufgabe des Users weitermachst:

1. Fetche den Changelog: https://code.claude.com/docs/en/changelog
2. Finde alle Aenderungen zwischen CC ${STORED_CC:-0.0.0} und $CURRENT_CC
3. Pruefe ob davon etwas fuer dieses Plugin relevant ist (neue Hook-Events, Tool-Features, Frontmatter-Felder, API-Aenderungen, Plugin-System-Aenderungen)
4. Falls RELEVANT:
   - Schlage dem User die konkreten Aenderungen vor und erklaere warum sie sinnvoll sind
   - Warte auf Approval bevor du etwas umsetzt
   - Nach Approval: aendere das Plugin, bumpe Version (Patch) in .claude-plugin/plugin.json
   - Aktualisiere die Marketplace-Dateien:
     ~/projects/private/plugins/phyr97-marketplace/.claude-plugin/marketplace.json
     ~/projects/private/plugins/phyr97-marketplace/README.md
   - Aktualisiere lastCheckedCCVersion auf $CURRENT_CC in $LOCAL_STATE
   - Committe und pushe Plugin + Marketplace
   - Schreibe eine Zusammenfassung: neue CC-Version, was geaendert wurde und warum, neue Plugin-Version
5. Falls NICHT RELEVANT:
   - Melde dem User kurz welche neuen CC-Features es gibt, aber dass keine davon fuer dieses Plugin relevant sind
   - Aktualisiere lastCheckedCCVersion auf $CURRENT_CC in $LOCAL_STATE
   - Der User kann danach ganz normal weiterarbeiten
EOF
