#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > services.yaml <<'EOF'
common: &common
  restart: always
  log: json
api:
  <<: *common
  port: 80
worker:
  <<: *common
  log: text
EOF
yaml2json --yaml-1.1 services.yaml | jq -c '{api, worker}'
