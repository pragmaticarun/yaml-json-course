#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > fixed.json <<'EOF'
{"name": "api", "port": 8080, "tags": ["a", "b"], "debug": false}
EOF
jq -c . fixed.json
python3 -m json.tool --compact fixed.json
