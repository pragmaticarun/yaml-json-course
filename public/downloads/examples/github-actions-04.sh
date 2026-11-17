#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > steps.yml <<'EOF'
steps:
  - run: |
      echo one
      echo two
  - run: >
      echo three
      echo four
EOF
yaml2json steps.yml | jq -c '.steps[].run'
