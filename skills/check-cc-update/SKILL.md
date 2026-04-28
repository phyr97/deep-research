---
name: check-cc-update
description: |
  Compare the current Claude Code version against the last verified plugin baseline and propose modernizations.
  Use when: "modernize plugin", "check cc update", "neue cc version", "plugin updaten", "claude code changelog gegen plugin".
  Manual gate — never auto-commits or pushes. Approval via MODERNIZATION-PROPOSAL.md.
---

# Plugin-Modernisierung

Du prüfst, ob neue Claude-Code-Features für dieses Plugin relevant sind, und schlägst Änderungen vor — mit explizitem User-Approval als Gate. Niemals automatisch committen oder pushen.

## Step 1: Versionen ermitteln

Aktuelle CC-Version per Bash:
```
claude --version
```

Letzten Check aus dem State-File lesen. Bevorzugt `$CLAUDE_PLUGIN_DATA/local-state.json` (persistent), fallback `.claude-plugin/local-state.json` im Plugin-Root. Feld: `lastCheckedCCVersion`.

Wenn die State-Datei nicht existiert oder das Feld leer ist: behandle als „noch nie geprüft".

Wenn `lastCheckedCCVersion == aktuelle CC-Version`: gib „kein Update-Check nötig" aus und beende.

## Step 2: Changelog fetchen

WebFetch `https://code.claude.com/docs/en/changelog` mit dem Prompt:
„Liste alle Änderungen zwischen Version X und Version Y, gruppiert nach Kategorie (Hooks, Tools, Plugins/Skills/Agents, Permissions, Settings, andere). Ignoriere reine UI/CLI-Änderungen ohne API-Auswirkungen."

Bei „noch nie geprüft" nimm die letzten 6 Monate als Range.

## Step 3: Relevanz prüfen

Filter auf Plugin-relevante Themen:

- Neue oder geänderte Hook-Events / Hook-Signaturen
- Neue oder restriktivere Tool-Features (z.B. Permission-Modes, neue Tools)
- Frontmatter-Felder in Agent- oder Skill-Definitionen
- Plugin-System-Änderungen (Marketplace, Subagent-Naming, Plugin-Discovery)
- Output- oder Hook-Format-Änderungen

Ignoriere: Statusline, Themes, IDE-Extensions, Pricing, allgemeine UX-Verbesserungen ohne API-Touch.

## Step 4: Proposal schreiben

Erstelle `MODERNIZATION-PROPOSAL.md` im Plugin-Root mit dieser Struktur:

```markdown
# Plugin-Modernisierung Proposal

- Aktuelle CC-Version: X.Y.Z
- Letzter Check: A.B.C (oder "nie")
- Datum: YYYY-MM-DD

## Relevante Änderungen

### 1. [Titel der Änderung]
- **Quelle**: Changelog-Eintrag, Release-Notes-URL
- **Auswirkung auf Plugin**: was würde sich ändern, welche Datei(en)
- **Empfehlung**: konkreter Edit-Vorschlag (kurze Begründung)
- **Priorität**: hoch / mittel / niedrig

### 2. [...]

## Nicht relevant (Notiz)
Kurze Liste der geprüften Changelog-Themen, die nicht angefasst wurden, mit einer Zeile warum.
```

Bei keiner relevanten Änderung: Datei trotzdem schreiben, mit Sektion „Keine Anpassung notwendig" und der Liste der geprüften Themen.

Zeige dem User die Datei und frage explizit:
- „Soll ich alle Vorschläge umsetzen?" — User antwortet z.B. „ja", „nur 1 und 3", „keinen", „lass die Punkte mit Priorität hoch".

Warte auf eine konkrete Antwort. „ok" allein ist nicht genug — frage nach falls die Antwort ambig ist.

## Step 5: Umsetzen (nur nach Approval)

Bei Approval:

1. Implementiere die ausgewählten Punkte. Kein Touch an nicht-approved Punkten.
2. Bump Plugin-Version in `.claude-plugin/plugin.json`:
   - Patch (z.B. 1.5.0 → 1.5.1) bei Cosmetics, Doku, kleinen Anpassungen
   - Minor (1.5.0 → 1.6.0) bei neuem Verhalten oder Feldern
   - Major (1.x → 2.0) bei breaking changes
3. Update `CLAUDE.md` Sektion „Plugin-Modernisierung":
   - `Plugin-Version` auf neue Version
   - `Letzter CC-Update-Check` auf aktuelle CC-Version + heutiges Datum
4. Update State-File (`.claude-plugin/local-state.json` oder `$CLAUDE_PLUGIN_DATA/local-state.json` — siehe Step 1) mit:
   ```json
   {"lastCheckedCCVersion": "<aktuelle CC-Version>"}
   ```
5. Lösche `MODERNIZATION-PROPOSAL.md`.

## Step 6: Bei No-Op

Wenn keine Änderung umgesetzt wird (Versionen identisch oder User lehnt alles ab):
- Update CLAUDE.md `Letzter CC-Update-Check` auf aktuelle CC-Version + heutiges Datum
- Update State-File mit `lastCheckedCCVersion = aktuelle CC-Version`
- Lösche `MODERNIZATION-PROPOSAL.md` falls vorhanden

So merkt sich das Plugin, dass es geprüft wurde, auch wenn nichts angepasst wurde.

## Step 7: Release-Hinweis

Am Ende sage dem User wörtlich:

> Änderungen liegen lokal. Nichts gepusht.
> Wenn alles passt: Plugin pushen, dann Marketplace-Bump per Hand. Siehe CLAUDE.md → Veröffentlichung.

**Niemals automatisch `git commit` oder `git push` ausführen.** Auch nicht „nur schnell" oder „weil's klar ist". Der User pusht, oder niemand.
