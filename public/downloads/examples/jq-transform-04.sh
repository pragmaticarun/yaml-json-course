#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '[{"id":1,"total":30,"items":["a"]},{"id":2,"total":15,"items":[]}]' > orders.json
echo "--- double every total"; jq -c 'map(.total |= . * 2) | map(.total)' orders.json
echo "--- add a field";        jq -c '.[0].tags = ["x"] | .[0]' orders.json
echo "--- drop a field";       jq -c 'map(del(.items))' orders.json
