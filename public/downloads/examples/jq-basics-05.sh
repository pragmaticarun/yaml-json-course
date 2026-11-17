#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > people.json <<'EOF'
[{"name":"Ada","role":"lead","age":36},{"name":"Bo","role":"dev","age":29}]
EOF
role=dev
jq -r --arg r "$role" '.[] | select(.role == $r) | .name' people.json
jq -c --argjson min 30 '.[] | select(.age >= $min) | .name' people.json
jq -n -c --arg n 3 '$n | tonumber + 1'
