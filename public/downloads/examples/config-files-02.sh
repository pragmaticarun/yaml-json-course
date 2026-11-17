#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > package.json <<'EOF'
{
  "name": "demo",
  "//": "the entry point is index.js",
  "main": "index.js"
}
EOF
jq -c '{name, main}' package.json
