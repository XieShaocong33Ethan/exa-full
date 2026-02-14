#!/bin/bash
# Exa Research: create an async research task (returns researchId)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

INSTRUCTIONS="$1"

if [ -z "$INSTRUCTIONS" ]; then
  echo "Usage: bash research_create.sh \"instructions\"" >&2
  echo "" >&2
  echo "Options (env vars):" >&2
  echo "  MODEL=exa-research        Research model: exa-research, exa-research-pro" >&2
  echo "  SCHEMA_FILE=path.json     JSON Schema file for outputSchema (optional)" >&2
  exit 1
fi

if [ -z "${EXA_API_KEY:-}" ]; then
  echo "Error: EXA_API_KEY is not set." >&2
  echo "Set EXA_API_KEY (env var or .env file)." >&2
  exit 1
fi

MODEL="${MODEL:-exa-research}"

if [ -n "${SCHEMA_FILE:-}" ]; then
  if [ ! -f "$SCHEMA_FILE" ]; then
    echo "Error: SCHEMA_FILE does not exist: $SCHEMA_FILE" >&2
    exit 1
  fi

  # Guard: reject files larger than 50MB
  _size="$(wc -c < "$SCHEMA_FILE")"
  if [ "$_size" -gt 52428800 ]; then
    echo "Error: SCHEMA_FILE exceeds 50MB limit: $SCHEMA_FILE" >&2
    exit 1
  fi

  OUTPUT_SCHEMA_JSON="$(jq -c '.' "$SCHEMA_FILE")"

  PAYLOAD="$(jq -n \
    --arg instructions "$INSTRUCTIONS" \
    --arg model "$MODEL" \
    --argjson outputSchema "$OUTPUT_SCHEMA_JSON" \
    '{ instructions: $instructions, model: $model, outputSchema: $outputSchema }')"
else
  PAYLOAD="$(jq -n \
    --arg instructions "$INSTRUCTIONS" \
    --arg model "$MODEL" \
    '{ instructions: $instructions, model: $model }')"
fi

curl -s -X POST 'https://api.exa.ai/research/v1' \
  -H "x-api-key: $EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD"

