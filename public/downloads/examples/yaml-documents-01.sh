#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > stream.yaml <<'EOF'
a: 1
---
b: 2
...
---
c: 3
EOF
echo "== without --all"
yaml2json stream.yaml || echo "(exit status $?)"
echo "== with --all"
yaml2json --all stream.yaml | jq -c .
echo "== yamlcheck"
yamlcheck stream.yaml
