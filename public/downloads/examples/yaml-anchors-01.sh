#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > anchors.yaml <<'EOF'
default_port: &port 8080
web:
  port: *port
admin:
  port: *port
list: &tags [a, b]
other: *tags
EOF
yaml2json anchors.yaml | jq -c .
