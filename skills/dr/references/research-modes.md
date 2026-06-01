# Research modes

## Web research
- Orchestrator dispatches scrapers via `subagent_type: "deep-research:dr-scraper-web"`
- Each scraper collects facts, URLs, snippets with source type tags for ONE narrow angle
- Each scraper receives a depth level (shallow/standard/deep) that controls search count and link-following
- Orchestrator clusters by theme across all scraper files in Step 4

## Codebase analysis
- Orchestrator dispatches scrapers via `subagent_type: "deep-research:dr-scraper-codebase"`
- Each scraper navigates code, extracts patterns, finds dependencies for one angle

## Knowledge synthesis
- Foundation comes from Opus's training data
- **MUST dispatch at least 2 web scrapers** to verify the top-3 claims before presenting
- Claims that survive fact-check get `[^N]` citations like all other modes
- Claims that fail fact-check or weren't verified must be removed or marked `[interpretation]`

## Mixed
- Orchestrator dispatches BOTH web and codebase scrapers per sub-question
- Allows direct comparison between local code and external best practices

## Depth levels

The orchestrator assigns a depth level per sub-question. The level controls (a) how many scrapers it dispatches for that sub-question and (b) how aggressively each scraper searches/follows.

| Depth | Scrapers | Searches per scraper | Follow links | Typical use |
|-------|---------|---------------------|-------------|-------------|
| shallow | 1-2 | 2 | 0 | Fact-checks, definitions, peripheral questions |
| standard | 2-4 | 3-4 | 1-2 | Regular research sub-questions |
| deep | 3-5 | 5-6 | up to 3 | Core question, needs thorough coverage |
