#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > refs.yaml <<'EOF'
a: &a [1, 2, 3]
b: [*a, *a, *a, *a]
EOF
for n in 1 2 5 10; do
  if yaml2json --max-alias-count $n refs.yaml > /dev/null 2>&1; then
    echo "limit $n: ok"
  else
    echo "limit $n: rejected"
  fi
done
