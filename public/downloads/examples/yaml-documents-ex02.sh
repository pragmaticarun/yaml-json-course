#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > hash.yaml <<'EOF'
x: 10 #ten
y: 10#ten
z: "10 #ten"
EOF
yaml2json hash.yaml | jq -c .
