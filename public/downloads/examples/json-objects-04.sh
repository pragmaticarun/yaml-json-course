#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"a": null, "c": 1}' > nul.json
echo "jq has(a), has(b):  $(jq -c '[has("a"), has("b")]' nul.json)"
echo "jq .a, .b:          $(jq -c '[.a, .b]' nul.json)"
echo "jq .a // dflt:      $(jq -c '[.a // "dflt", .c // "dflt"]' nul.json)"
python3 - <<'EOF'
import json
d = json.load(open("nul.json"))
print("python d.get:       ", d.get("a"), d.get("b"))
print("python in:          ", "a" in d, "b" in d)
EOF
node -e '
const d = JSON.parse(require("fs").readFileSync("nul.json", "utf8"));
console.log("node values:        ", d.a, d.b);
console.log("node in:            ", "a" in d, "b" in d);
console.log("node stringify:     ", JSON.stringify({x: undefined, y: null}));
'
