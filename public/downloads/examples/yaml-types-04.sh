#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > safe.yaml <<'EOF'
countries: [GB, "NO", DE]
code: !!str 010
duration: "1:30"
version: "3.10"
EOF
echo "== YAML 1.2"
yaml2json safe.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 safe.yaml | jq -c .
