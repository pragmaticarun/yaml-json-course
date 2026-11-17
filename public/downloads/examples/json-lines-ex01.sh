#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"lvl":"info"}\n{"lvl":"error"}\n{"lvl":"info"}\n{"lvl":"warn"}\n' > l.jsonl
jq -s -c 'group_by(.lvl) | map({(.[0].lvl): length}) | add' l.jsonl
