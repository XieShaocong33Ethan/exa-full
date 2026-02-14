---
name: exa-full
version: 1.2.0
description: Exa AI search + Research API. Supports web/code search, content extraction, and async multi-step research tasks with outputSchema.
homepage: https://exa.ai
metadata: {"openclaw":{"emoji":"🔍","requires":{"bins":["curl","jq"],"env":["EXA_API_KEY"]}}}
---

# Exa - Search + Research

Powerful AI-powered search + content extraction + async research tasks.

## Setup

**Option A** – Environment variable:
```bash
export EXA_API_KEY="your-exa-api-key"
```

**Option B** – `.env` file in the skill root directory:
```bash
# .env (placed next to SKILL.md)
EXA_API_KEY=your-exa-api-key
```
If `EXA_API_KEY` is not set, scripts auto-load from the skill root `.env`. Only `EXA_API_KEY` is read; other variables in the file are ignored.

## Commands

### General Search
```bash
bash scripts/search.sh "query" [options]
```

Options (as env vars):
- `NUM=10` - Number of results (max 100)
- `TYPE=auto` - Search type: auto, neural, fast, deep, instant
- `CATEGORY=` - Category: company, research paper, news, tweet, personal site, financial report, people
- `DOMAINS=` - Include domains (comma-separated)
- `EXCLUDE=` - Exclude domains (comma-separated). **Not supported** with `CATEGORY=company` or `CATEGORY=people` (API returns INVALID_REQUEST_BODY).
- `SINCE=` - Published after (ISO date). **Not supported** with `CATEGORY=company` or `CATEGORY=people` (script will skip this filter with a warning).
- `UNTIL=` - Published before (ISO date). **Not supported** with `CATEGORY=company` or `CATEGORY=people` (script will skip this filter with a warning).
- `LOCATION=NL` - User location (country code)

Notes:
- With `CATEGORY=people`, `DOMAINS` only accepts LinkedIn domains (e.g. `linkedin.com`, `www.linkedin.com`, `*.linkedin.com`).

### LLM Guidance: Choosing `TYPE`

When an LLM is using this skill, it should select `TYPE` using the policy below instead of always relying on defaults.

Search type comparison:

| Type | Latency | Best for |
| --- | --- | --- |
| `auto` | ~1s | Highest quality results (default) |
| `instant` | sub-150ms | Real-time applications, autocomplete |
| `fast` | ~500ms | Speed/quality balance |
| `deep` | ~5s | Comprehensive research tasks |

Selection policy (must follow):
1. If the user explicitly asks for low latency, realtime behavior, live suggestions, or autocomplete, use `TYPE=instant`.
2. If the task needs broad coverage, deeper synthesis, or comprehensive research, use `TYPE=deep`.
3. If the user asks for a speed/quality balance, or latency is important but not strictly realtime, use `TYPE=fast`.
4. Otherwise use `TYPE=auto` as the default high-quality mode.

Override rules:
- User's explicit requirement has highest priority.
- If search is too slow or time-sensitive, step down one level: `deep -> auto -> fast -> instant`.
- If returned results are too shallow, step up one level: `instant -> fast -> auto -> deep`.

Recommended execution pattern for agents:
```bash
# Decide TYPE first, then call search
TYPE=auto bash scripts/search.sh "query"
```

Examples:
```bash
# Realtime UX / autocomplete
TYPE=instant bash scripts/search.sh "best ramen near me open now"

# General high-quality lookup
TYPE=auto bash scripts/search.sh "latest AI model release notes"

# Balanced speed and quality
TYPE=fast bash scripts/search.sh "top battery recycling companies europe"

# Deep, comprehensive search
TYPE=deep bash scripts/search.sh "long-term impact of solid-state batteries on EV supply chain"
```

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
- `SUBPAGES=10` - Crawl up to N subpages (see [Crawling Subpages](https://docs.exa.ai/reference/crawling-subpages)). Prefer `https://docs.exa.ai/` over `https://exa.ai/docs/reference/` (后者 subpages 会返回 CRAWL_NOT_FOUND).
- `SUBPAGE_TARGET="docs,tutorial"` - Comma-separated subpage targets
- `LIVECRAWL=preferred` - `"preferred" | "always" | "fallback"`
- `LIVECRAWL_TIMEOUT=12000` - Livecrawl timeout (ms)

Examples:
```bash
# Discover docs pages via llms.txt
MAX_CHARACTERS=10000 bash scripts/content.sh "https://exa.ai/docs/llms.txt" | jq

# Crawl docs subpages starting from a seed page (use docs.exa.ai; exa.ai/docs/reference/ returns CRAWL_NOT_FOUND)
SUBPAGES=10 SUBPAGE_TARGET="docs,reference,api" LIVECRAWL=preferred LIVECRAWL_TIMEOUT=12000 \
  bash scripts/content.sh "https://docs.exa.ai/" | jq
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
