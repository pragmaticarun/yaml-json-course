#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"n":1}\n{"n":2}\n{"n":3}\n' > lines.json
echo "--- without -s, once per value"; jq -c '.n' lines.json
echo "--- with -s, once overall";     jq -c -s '{count: length, sum: (map(.n) | add)}' lines.json
