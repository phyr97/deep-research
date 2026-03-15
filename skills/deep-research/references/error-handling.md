# Error handling

## WebFetch failures
- Scraper level: 1 retry, then mark "source inaccessible" and continue
- Analyst level: flag "insufficient data for sub-question X" rather than hallucinate
- Orchestrator level: surface gaps in "Contradictions & Open Questions"

## Vague research questions
If the topic is too vague for meaningful sub-questions, ask the user to narrow down. Suggest 2-3 more specific angles.

## Scraper quality issues
If a scraper returns off-topic or nonsensical results, the analyst discards the output and notes the gap.
