#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > in.yaml <<'EOF'
# build
base: &b {os: linux}
ci: *b
v: !!str 1
EOF
yaml2json in.yaml | tee out.json
json2yaml out.json
