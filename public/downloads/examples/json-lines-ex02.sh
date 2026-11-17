#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '[{"id":1},{"id":2},{"id":3}]' > a.json
jq -c '.[]' a.json > a.jsonl
cat a.jsonl
jq -s -c . a.jsonl
