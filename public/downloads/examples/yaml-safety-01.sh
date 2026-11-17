#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > payload.yaml <<'EOF'
!!python/object/apply:os.system ["echo hi"]
EOF
echo "== yaml2json"
yaml2json payload.yaml | jq -c .
echo "== yamlcheck"
yamlcheck payload.yaml
