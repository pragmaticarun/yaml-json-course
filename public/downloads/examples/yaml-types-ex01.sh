#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > flags.yaml <<'EOF'
flags: [on, off]
region: no
build: 007
EOF
echo "== 1.2"; yaml2json flags.yaml | jq -c .
echo "== 1.1"; yaml2json --yaml-1.1 flags.yaml | jq -c .
cat > fixed.yaml <<'EOF'
flags: ["on", "off"]
region: "no"
build: "007"
EOF
echo "== fixed, 1.2"; yaml2json fixed.yaml | jq -c .
echo "== fixed, 1.1"; yaml2json --yaml-1.1 fixed.yaml | jq -c .
