#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > ref.yaml <<'EOF'
a: !Ref Bucket
b: !!str 7
EOF
yaml2json ref.yaml | jq -c .
