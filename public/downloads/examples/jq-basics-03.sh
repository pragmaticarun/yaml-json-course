#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > people.json <<'EOF'
[{"name":"Ada"},{"name":"Cy","email":"cy@example.com"}]
EOF
echo "--- .email on each";     jq -c '.[].email' people.json
echo "--- with a default";     jq -c '.[] | .email // "none"' people.json
echo '{"a":1}' > num.json
echo "--- indexing a number";  jq '.a[0]' num.json 2>&1 || echo "(exit status $?)"
echo "--- with ?";             jq '.a[0]?' num.json; echo "(exit status $?)"
