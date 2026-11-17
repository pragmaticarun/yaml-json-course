#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
node -e 'const m = Number.MAX_SAFE_INTEGER; console.log(m + 1 === m + 2)'
echo '9007199254740993' | jq .
