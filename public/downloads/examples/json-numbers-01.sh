#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > n.json <<'EOF'
{"id": 9007199254740993, "big": 12345678901234567890123, "f": 1.0, "e": 1E2, "pi": 3.14159265358979323846264}
EOF
echo "--- jq -c"; jq -c . n.json
echo "--- node"
node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("n.json","utf8"))))'
echo "--- python"
python3 -c 'import json; print(json.dumps(json.load(open("n.json"))))'
