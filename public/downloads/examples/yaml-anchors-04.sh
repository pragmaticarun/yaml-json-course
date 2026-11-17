#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > merge.yaml <<'EOF'
base: &base
  retries: 3
  timeout: 30
svc:
  <<: *base
  timeout: 60
EOF
echo "== YAML 1.2 (default)"
yaml2json merge.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 merge.yaml | jq -c .
