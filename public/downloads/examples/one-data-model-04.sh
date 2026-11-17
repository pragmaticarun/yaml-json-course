#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"name": "api",}\n' > trailing-comma.json
echo "As YAML (yaml2json accepts this flow mapping):"
yaml2json trailing-comma.json
echo "As strict JSON (json2yaml uses JSON.parse):"
json2yaml trailing-comma.json
