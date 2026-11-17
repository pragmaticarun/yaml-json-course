#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > quote.yaml <<'EOF'
path: 'C:\temp\new'
note: 'note: remember'
handle: '@home'
EOF
yaml2json quote.yaml | jq -c .
