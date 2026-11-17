#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > cases.txt <<'EOF'
{"a":1,}
{'a':1}
{a:1}
{"a":01}
{"a":NaN}
{"a":Infinity}
EOF
while IFS= read -r text; do
  printf '%s\n' "$text" > t.json
  echo "--- $text"
  echo "jq:     $(jq -c . t.json 2>&1 | head -1)"
  echo "node:   $(node -e 'try{console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("t.json","utf8"))))}catch(e){console.log("ERROR",e.message.split("\n")[0].slice(0,60))}')"
  echo "python: $(python3 -c '
import json
try: print(json.dumps(json.load(open("t.json"))))
except Exception as e: print("ERROR", e)')"
done < cases.txt
