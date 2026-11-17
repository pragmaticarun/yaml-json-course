#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > people.json <<'EOF'
{"members":[{"name":"Ada","role":"lead"},{"name":"Bo","role":"dev"},{"name":"Cy","role":"dev"}]}
EOF
jq -r '.members[] | select(.role == "dev") | .name' people.json
