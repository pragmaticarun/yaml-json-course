#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > order.yaml <<'EOF'
p: &p {k: 1, other: 1}
q: &q {k: 2, extra: 2}
first_wins: {<<: [*p, *q]}
reversed:   {<<: [*q, *p]}
explicit:   {<<: *p, k: 9}
EOF
yaml2json --yaml-1.1 order.yaml | jq -c '{first_wins, reversed, explicit}'
