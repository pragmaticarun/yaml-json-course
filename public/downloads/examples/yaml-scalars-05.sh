#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > multi.yaml <<'EOF'
multi: first line
  second line

  after blank
EOF
yaml2json multi.yaml | jq -c .
