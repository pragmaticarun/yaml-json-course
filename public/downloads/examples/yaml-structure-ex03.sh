#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > deploy.yaml <<'EOF'
deploy:
  - build
  - test
   - ship
EOF
yaml2json deploy.yaml | jq -c .
yaml2json deploy.yaml | jq '.deploy | length'
sed -i 's/^   - ship/  - ship/' deploy.yaml
yaml2json deploy.yaml | jq '.deploy | length'
