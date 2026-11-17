#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > team.yaml <<'EOF'
name: platform
members:
  - name: Ada
    role: lead
  - name: Grace
    role: engineer
  - name: Linus
    role: engineer
EOF
yaml2json team.yaml | jq '.members | length'
