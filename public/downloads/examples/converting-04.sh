#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > odd.yaml <<'EOF'
count: !!str 12
ref: !Ref MyBucket
1: one
true: "yes"
? [a, b]
: pair
null: nothing
EOF
yaml2json odd.yaml
