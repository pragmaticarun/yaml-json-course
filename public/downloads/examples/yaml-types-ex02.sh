#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > matrix.yaml <<'EOF'
python: ["3.8", "3.9", "3.10"]
EOF
yaml2json matrix.yaml | jq -c .
