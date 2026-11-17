#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > ids.json <<'EOF'
{"as_number": 9007199254740993, "as_string": "9007199254740993"}
EOF
echo "jq reads the number:"; jq '.as_number' ids.json
echo "jq reads the string:"; jq '.as_string' ids.json
echo "converting the string to a number in jq 1.6:"; jq '.as_string | tonumber' ids.json
echo "node, comparing:"
node -e '
const d = JSON.parse(require("fs").readFileSync("ids.json", "utf8"));
console.log(String(d.as_number), d.as_string, String(d.as_number) === d.as_string);
'
