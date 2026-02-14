---
name: exa-full
version: 1.1.0
description: Exa AI search + Research API. Supports web/code search, content extraction, and async multi-step research tasks with outputSchema.
homepage: https://exa.ai
metadata: {"openclaw":{"emoji":"🕵️‍♀️","requires":{"bins":["curl","jq"],"env":["EXA_API_KEY"]}}}
---

# Exa - Search + Research

Powerful AI-powered search + content extraction + async research tasks.

## Setup

**Option A** – Environment variable:
```bash
export EXA_API_KEY="your-exa-api-key"
```

**Option B** – `.env` file (skill root only):
```bash
# exa_oc/.env
EXA_API_KEY=your-exa-api-key
```
If `EXA_API_KEY` is not set, scripts auto-load from `exa_oc/.env`. Only `EXA_API_KEY` is read; other variables in the file are ignored.

## Commands

### General Search
```bash
bash scripts/search.sh "query" [options]
```

Options (as env vars):
- `NUM=10` - Number of results (max 100)
- `TYPE=auto` - Search type: auto, neural, fast, deep
- `CATEGORY=` - Category: news, company, people, research paper, github, tweet, pdf, financial report
- `DOMAINS=` - Include domains (comma-separated)
- `EXCLUDE=` - Exclude domains (comma-separated)
- `SINCE=` - Published after (ISO date)
- `UNTIL=` - Published before (ISO date)
- `LOCATION=NL` - User location (country code)

### Examples

```bash
# Basic search
bash scripts/search.sh "AI agents 2024"

# LinkedIn people search
CATEGORY=people bash scripts/search.sh "software engineer Amsterdam"

# Company search
CATEGORY=company bash scripts/search.sh "fintech startup Netherlands"

# News from specific domain
CATEGORY=news DOMAINS="reuters.com,bbc.com" bash scripts/search.sh "Netherlands"

# Research papers
CATEGORY="research paper" bash scripts/search.sh "transformer architecture"

# Deep search (comprehensive)
TYPE=deep bash scripts/search.sh "climate change solutions"

# Date-filtered news
CATEGORY=news SINCE="2026-01-01" bash scripts/search.sh "tech layoffs"
```

### Code Context Search
```bash
bash scripts/code.sh "query" [num_results]
```

### Get Content
Extract full text from URLs:
```bash
bash scripts/content.sh "url1" "url2"
```

Optional env vars (contents + crawling):
- `MAX_CHARACTERS=2000` - Max characters per page
- `HIGHLIGHT_SENTENCES=3` - Sentences per highlight
- `HIGHLIGHTS_PER_URL=2` - Highlights per URL
- `SUBPAGES=10` - Crawl up to N subpages (see [Crawling Subpages](https://exa.ai/docs/reference/crawling-subpages))
- `SUBPAGE_TARGET="docs,tutorial"` - Comma-separated subpage targets
- `LIVECRAWL=preferred` - `"preferred" | "always" | "fallback"`
- `LIVECRAWL_TIMEOUT=12000` - Livecrawl timeout (ms)

Examples:
```bash
# Discover docs pages via llms.txt
MAX_CHARACTERS=10000 bash scripts/content.sh "https://exa.ai/docs/llms.txt" | jq

# Crawl docs subpages starting from a seed page
SUBPAGES=10 SUBPAGE_TARGET="docs,reference,api" LIVECRAWL=preferred LIVECRAWL_TIMEOUT=12000 \
  bash scripts/content.sh "https://exa.ai/docs/reference/" | jq
```

### Exa Research (Async)
Docs (params/status/polling): [`https://exa.ai/docs/reference/exa-research`](https://exa.ai/docs/reference/exa-research)

#### One-shot (create + poll until finished)
```bash
bash scripts/research.sh "Compare the current flagship GPUs from NVIDIA, AMD and Intel."
```

Optional env vars:
- `MODEL=exa-research` (default) or `MODEL=exa-research-pro`
- `SCHEMA_FILE=path/to/schema.json` (optional, used as `outputSchema`)
- `POLL_INTERVAL=2` (seconds between polls)
- `MAX_WAIT_SECONDS=240` (timeout in seconds)
- `EVENTS=true` (include event log in responses)

#### Two-step workflow (create, then poll)
```bash
# Create
bash scripts/research_create.sh "Estimate the global market size for battery recycling in 2030." | jq

# Extract researchId
RID="$(bash scripts/research_create.sh "Create a timeline of major OpenAI product releases from 2015 to 2023." | jq -r '.researchId')"

# Poll until finished
bash scripts/research_poll.sh "$RID" | jq
```

### Agent-friendly workflow (recommended)
- Use `scripts/search.sh` to find relevant URLs (optionally narrow with `DOMAINS` and `CATEGORY`)
- Use `scripts/content.sh` to pull full text and (when appropriate) crawl subpages
- Use `scripts/research.sh` when you need multi-source synthesis with citations / structured output
