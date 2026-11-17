#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > dup.yaml <<'EOF'
services:
  - {name: api, port: 8080}
  - {name: api, port: 9090}
EOF
yaml2json dup.yaml | jq -r '[.services[].name] | group_by(.)[] | select(length > 1) | "duplicate name: " + .[0]'
