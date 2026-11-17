#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > ports.yaml <<'EOF'
ports:
  - 22:22
  - "22:22"
  - 8080:80
EOF
echo "--- YAML 1.2 ---"
yaml2json ports.yaml | jq -c .ports
echo "--- YAML 1.1 ---"
yaml2json --yaml-1.1 ports.yaml | jq -c .ports
