#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '[1.0, 1.50, 100]' > r.json
jq -c . r.json
python3 -c 'import json; print(json.dumps(json.load(open("r.json"))))'
