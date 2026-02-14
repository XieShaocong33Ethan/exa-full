#!/bin/bash
# Exa content extraction from URLs

if [ $# -eq 0 ]; then
    echo "Usage: bash content.sh \"url1\" \"url2\" ..." >&2
    exit 1
fi

if [ -z "${EXA_API_KEY:-}" ]; then
    echo "Error: EXA_API_KEY is not set." >&2
    echo "Please set EXA_API_KEY environment variable." >&2
    exit 1
fi

# Build URLs array
URLS=$(printf '%s\n' "$@" | jq -R . | jq -s .)

# Build payload
PAYLOAD=$(jq -n \
    --argjson urls "$URLS" \
    '{
        urls: $urls,
        text: { maxCharacters: 2000 },
        highlights: { numSentences: 3, highlightsPerUrl: 2 },
        summary: {}
    }')

# Call API
curl -s -X POST 'https://api.exa.ai/contents' \
    -H "x-api-key: $EXA_API_KEY" \
    -H 'Content-Type: application/json' \
    -d "$PAYLOAD"
