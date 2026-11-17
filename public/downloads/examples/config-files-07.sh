#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > ids.yaml <<'EOF'
zip: 02134
phone: 5551234
version: 1.10
build: "0042"
EOF
yaml2json ids.yaml | jq -c '.'
yaml2json ids.yaml | jq -c 'map_values(type)'
