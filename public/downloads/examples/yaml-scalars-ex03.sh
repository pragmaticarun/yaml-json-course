#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > desc.yaml <<'EOF'
description: >-
  This sentence is wrapped across
  three lines in the source file
  but loads as one.
EOF
yaml2json desc.yaml | jq -r .description
