#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
: > empty.json
jq -c . empty.json; echo "jq exit: $?"
python3 -c 'import json; json.load(open("empty.json"))' 2>&1 | tail -1 || true
