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
echo "--- .team";                 jq '.team' people.json
echo "--- .team with -r";         jq -r '.team' people.json
echo "--- .members[0].name";      jq '.members[0].name' people.json
echo "--- .members[].name";       jq '.members[].name' people.json
echo "--- slice [1:], -c";        jq -c '.members[1:] | map(.name)' people.json
echo "--- last element, -c";      jq -c '.members[-1]' people.json
