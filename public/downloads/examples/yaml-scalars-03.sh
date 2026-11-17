#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > blocks.yaml <<'EOF'
literal: |
  line one
    indented
  line three
folded: >
  folded text
  continues here

  new paragraph
EOF
yaml2json blocks.yaml | jq -c .
