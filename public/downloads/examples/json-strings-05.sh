#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '\xef\xbb\xbf{"a":1}' > bom.json
printf '{"a":"\xff"}' > bad8.json
echo "--- BOM"
jq -c . bom.json
python3 -c 'import json; print(json.load(open("bom.json")))' 2>&1 | tail -1 || true
node -e 'try{JSON.parse(require("fs").readFileSync("bom.json","utf8"))}catch(e){console.log("node:",e.name)}'
echo "--- byte 0xFF inside a string"
jq -c . bad8.json
python3 -c 'import json; print(json.load(open("bad8.json")))' 2>&1 | tail -1 || true
