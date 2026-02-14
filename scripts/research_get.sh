#!/bin/bash
# Exa Research: get a research task by researchId

RESEARCH_ID="$1"

if [ -z "$RESEARCH_ID" ]; then
  echo "Usage: bash research_get.sh \"researchId\"" >&2
  echo "" >&2
  echo "Options (env vars):" >&2
  echo "  EVENTS=true     Include detailed event log" >&2
  exit 1
fi

if [ -z "${EXA_API_KEY:-}" ]; then
  echo "Error: EXA_API_KEY is not set." >&2
  echo "Please set EXA_API_KEY environment variable." >&2
  exit 1
fi

URL="https://api.exa.ai/research/v1/${RESEARCH_ID}"

if [ "${EVENTS:-false}" = "true" ]; then
  URL="${URL}?events=true"
fi

curl -s -X GET "$URL" \
  -H "x-api-key: $EXA_API_KEY" \
  -H 'Content-Type: application/json'

