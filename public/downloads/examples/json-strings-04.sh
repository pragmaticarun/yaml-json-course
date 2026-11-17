#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"a":"x\ty"}\n' > ctl.json
jq -c . ctl.json 2>&1 | head -1 || true
node -e 'try{JSON.parse(require("fs").readFileSync("ctl.json","utf8"))}catch(e){console.log("node:",e.message)}'
python3 - <<'EOF'
import json
try:
    json.load(open("ctl.json"))
except Exception as err:
    print("python:", err)
print("python, strict=False:", json.loads(open("ctl.json").read(), strict=False))
EOF
