---
name: deep-research
description: Start a deep research session across web, codebase, and knowledge domains
arguments:
  - name: topic
    description: The research question or topic (quoted)
    required: true
  - name: --mode
    description: "Force research mode: web, codebase, knowledge, or mixed"
    required: false
---

Invoke the `deep-research:deep-research` skill with the following input:

- **Topic**: $ARGUMENTS
- Parse any options (--mode) from the arguments
- If no options detected, pass the full argument string as the topic

The skill handles everything: mode detection, auto-scaling, analyst dispatch, self-check, synthesis, and metrics.
