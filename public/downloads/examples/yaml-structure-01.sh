#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > app.yaml <<'EOF'
name: shop
owner:
  team: payments
  oncall: true
ports:
  - 80
  - 443
limits:
  cpu: 2
  memory: 512
EOF
yaml2json app.yaml | jq -c .
