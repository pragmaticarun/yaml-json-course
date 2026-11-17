#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
for text in '42' '"hi"' 'null' 'true' '[]'; do
  printf '%s\n' "$text" > doc.json
  printf '%-6s jq=%s' "$text" "$(jq -c . doc.json)"
  printf ' node=%s' "$(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("doc.json","utf8"))))')"
  printf ' python=%s\n' "$(python3 -c 'import json; print(json.dumps(json.load(open("doc.json"))))')"
done
