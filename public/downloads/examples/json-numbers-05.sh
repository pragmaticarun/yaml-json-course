#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"s": 1e400}' > huge.json
echo "jq:     $(jq -c . huge.json)"
echo "node:   $(node -e 'const d = JSON.parse(require("fs").readFileSync("huge.json","utf8")); console.log(d.s, JSON.stringify(d))')"
echo "python: $(python3 -c 'import json; d = json.load(open("huge.json")); print(d["s"], json.dumps(d))')"
