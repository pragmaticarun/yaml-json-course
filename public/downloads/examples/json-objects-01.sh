#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"a":1,"b":2,"a":3}' > dup.json
echo "jq:     $(jq -c . dup.json)"
echo "node:   $(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("dup.json","utf8"))))')"
echo "python: $(python3 -c 'import json; print(json.dumps(json.load(open("dup.json"))))')"
echo "yaml2json:"
yaml2json dup.json || echo "(exit status $?)"
