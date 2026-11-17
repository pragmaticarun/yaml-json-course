#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > mixed.yaml <<'EOF'
tags: [web, public]
resources: {cpu: 2, memory: 512}
empty_list: []
empty_map: {}
no_value:
EOF
yaml2json mixed.yaml | jq -c .
