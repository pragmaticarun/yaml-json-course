#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > types.yaml <<'EOF'
[1, 1.0, "1", true, "true", ~, '']
EOF
yaml2json types.yaml | jq -c 'map(type)'
