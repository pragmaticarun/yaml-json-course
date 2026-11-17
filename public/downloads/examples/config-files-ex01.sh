#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > env.yaml <<'EOF'
PORT: 8080
ENABLED: yes
VERSION: 3.10
EOF
yaml2json env.yaml | jq -c 'map_values(type)'
yaml2json env.yaml | jq -c .VERSION
printf 'PORT: "8080"\nENABLED: "yes"\nVERSION: "3.10"\n' > env-strings.yaml
yaml2json env-strings.yaml | jq -c 'map_values(type)'
