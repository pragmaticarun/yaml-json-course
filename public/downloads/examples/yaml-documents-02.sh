#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > comments.yaml <<'EOF'
a: 1 # a comment
b: 2#not a comment
# a whole-line comment
c: "x # y"
EOF
yaml2json comments.yaml | jq -c .
