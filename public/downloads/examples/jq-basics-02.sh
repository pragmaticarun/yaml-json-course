#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > people.json <<'EOF'
{"team":"core","members":[
 {"name":"Ada","role":"lead","langs":["c","python"],"active":true},
 {"name":"Bo","role":"dev","langs":["go"],"active":false},
 {"name":"Cy","role":"dev","langs":[],"active":true,"email":"cy@example.com"}
]}
EOF
echo "--- active members";  jq -c '.members[] | select(.active) | .name' people.json
echo "--- active devs";     jq -c '.members[] | select(.role == "dev" and .active) | {name}' people.json
echo "--- sizes";           jq -c 'keys, (.members | length), (.members[0] | keys)' people.json
