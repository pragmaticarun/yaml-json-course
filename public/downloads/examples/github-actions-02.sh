#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > trigger.yml <<'EOF'
on:
  push:
    branches: [main]
EOF
echo "--- YAML 1.2 ---"
yaml2json trigger.yml | jq -c 'keys'
echo "--- YAML 1.1 ---"
yaml2json --yaml-1.1 trigger.yml | jq -c 'keys'
