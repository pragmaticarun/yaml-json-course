#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > two.yaml <<'EOF'
kind: Service
---
kind: Deployment
EOF
yaml2json --all two.yaml | jq -r '.[].kind'
