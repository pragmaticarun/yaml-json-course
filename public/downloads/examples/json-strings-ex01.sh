#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '["\\u00e9","\\ud83d\\ude00"]\n' > decode.json
jq -r '.[]' decode.json
jq -a -c . decode.json
