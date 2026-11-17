#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > docs.yaml <<'EOF'
kind: config
---
kind: data
items: [1, 2]
EOF
yaml2json --all docs.yaml | jq -r '.[].kind'
