# Research modes

## Web research
- Analysts spawn web scrapers via `subagent_type: "deep-research:dr-scraper-web"`
- Scrapers collect facts, URLs, snippets with source type tags
- Analysts cluster and evaluate

## Codebase analysis
- Analysts spawn codebase scrapers via `subagent_type: "deep-research:dr-scraper-codebase"`
- Scrapers navigate code, extract patterns, find dependencies
- Analysts build focused analysis of their area

## Knowledge synthesis
- Orchestrator (Opus) synthesizes directly, no analyst dispatch
- Optionally spawn 1-2 web scrapers for fact-checking specific claims

## Mixed
- Analysts may spawn BOTH web and codebase scrapers
- Allows direct comparison between local code and external best practices
- Analyst decides per sub-task which scraper type to spawn
