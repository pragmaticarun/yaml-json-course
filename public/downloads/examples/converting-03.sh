#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > stream.yaml <<'EOF'
kind: Service
name: api
---
kind: Job
name: migrate
EOF
yaml2json --all stream.yaml | jq -c '.[]'
echo "--- just the names ---"
yaml2json --all stream.yaml | jq -r '.[].name'
