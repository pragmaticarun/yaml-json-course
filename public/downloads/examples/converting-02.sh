#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > one.yaml <<'EOF'
# deployment defaults
defaults: &d
  retries: 3   # per request
copy: *d
EOF
yaml2json one.yaml
echo "--- and back to YAML ---"
yaml2json one.yaml | json2yaml
