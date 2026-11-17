#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '// the port\n{"port": 8080}\n' > commented.json
jq -c . commented.json 2>&1 | head -1 || true
python3 -c 'import json; json.load(open("commented.json"))' 2>&1 | tail -1 || true
