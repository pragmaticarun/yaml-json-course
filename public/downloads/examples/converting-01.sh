#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > multi.yaml <<'EOF'
# deployment defaults
defaults: &d
  retries: 3   # per request
service:
  <<: *d
  name: api
copy: *d
---
second: true
EOF
yaml2json multi.yaml
