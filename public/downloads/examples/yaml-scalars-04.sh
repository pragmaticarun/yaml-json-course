#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > chomp.yaml <<'EOF'
clip: |
  one newline
strip: |-
  no trailing newline
keep: |+
  keeps newlines


indicator: |2
    two extra spaces
EOF
yaml2json chomp.yaml | jq -c .
