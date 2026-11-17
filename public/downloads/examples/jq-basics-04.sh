#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > people.json <<'EOF'
[{"name":"Ada","active":true},{"name":"Bo","active":false}]
EOF
if jq -e '.[] | select(.name == "Zed")' people.json > /dev/null; then
  echo "Zed found"
else
  echo "Zed not found (jq exit status $?)"
fi
jq -r '.[] | [.name, (.active | tostring)] | @tsv' people.json
