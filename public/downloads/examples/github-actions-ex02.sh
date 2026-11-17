#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > m.yml <<'EOF'
matrix:
  os: [ubuntu-latest, macos-latest, windows-latest]
  node: [20, 22]
EOF
yaml2json m.yml | jq '[.matrix[] | length] | reduce .[] as $n (1; . * $n)'
