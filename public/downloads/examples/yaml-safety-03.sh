#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > small.yaml <<'EOF'
a: &a [x, x, x, x]
b: &b [*a, *a, *a, *a]
c: &c [*b, *b, *b, *b]
EOF
echo "== default limit"
yaml2json small.yaml | jq -c '.c | flatten | length'
echo "== limit 10"
yaml2json --max-alias-count 10 small.yaml || echo "(exit status $?)"
