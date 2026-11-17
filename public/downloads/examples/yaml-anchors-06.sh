#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > shallow.yaml <<'EOF'
defaults: &d
  env: {A: 1}
  tags: [x]
over:
  <<: *d
  env: {B: 2}
EOF
yaml2json --yaml-1.1 shallow.yaml | jq -c .over
