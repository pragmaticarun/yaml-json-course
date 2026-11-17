#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > nulls.yaml <<'EOF'
tilde: ~
empty:
word: null
inf: .inf
nan: .nan
hex: 0x1F
plus: +12
exp: 1e3
date: 2024-01-15
EOF
echo "== YAML 1.2"
yaml2json nulls.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 nulls.yaml | jq -c .
