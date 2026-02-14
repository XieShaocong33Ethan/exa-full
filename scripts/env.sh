#!/bin/bash
# Load EXA_API_KEY from .env if not set (option B)
if [ -z "${EXA_API_KEY:-}" ]; then
  _dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  for _f in "$_dir/../.env" "./.env"; do
    if [ -f "$_f" ]; then
      set -a
      # shellcheck disable=SC1090
      source "$_f"
      set +a
      break
    fi
  done
  unset _dir _f
fi
