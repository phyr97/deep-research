# Research modes

## Web research
- Analysts spawn web scrapers via `subagent_type: "deep-research:dr-scraper-web"`
- Scrapers collect facts, URLs, snippets with source type tags
- Analysts cluster and evaluate
- Each scraper receives a depth level (shallow/standard/deep) that controls search count and link-following

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

## Depth levels

The orchestrator assigns a depth level per sub-question. Analysts pass this depth to their web scrapers.

| Depth | Scraper searches | Follow links | Typical use |
|-------|-----------------|-------------|-------------|
| shallow | 2 | 0 | Fact-checks, definitions, peripheral questions |
| standard | 3-4 | 1-2 | Regular research sub-questions |
| deep | 5-6 | up to 3 | Core question, needs thorough coverage |

Depth does not affect codebase scrapers, only web scrapers. Codebase scrapers always search thoroughly within their maxTurns budget.
