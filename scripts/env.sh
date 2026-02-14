#!/bin/bash
# Load EXA_API_KEY from .env if not already set
if [ -z "${EXA_API_KEY:-}" ]; then
  _env_file="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/../.env"
  if [ -f "$_env_file" ]; then
    # Safe parse: only extract EXA_API_KEY lines, never execute .env content
    _val="$(grep -E '^(export[[:space:]]+)?EXA_API_KEY=' "$_env_file" | tail -n1 | sed 's/^export[[:space:]]*//' | cut -d'=' -f2-)"
    # Strip optional surrounding quotes
    _val="${_val#\"}" ; _val="${_val%\"}"
    _val="${_val#\'}" ; _val="${_val%\'}"
    if [ -n "$_val" ]; then
      export EXA_API_KEY="$_val"
    fi
  fi
  unset _env_file _val
fi
