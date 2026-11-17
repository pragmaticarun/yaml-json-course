#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > script.yaml <<'EOF'
with_nl: |
  echo hi
without_nl: |-
  echo hi
EOF
yaml2json script.yaml | jq -c '{with_nl: (.with_nl | length), without_nl: (.without_nl | length)}'
