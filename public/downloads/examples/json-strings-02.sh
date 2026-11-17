#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"e":"caf\\u00e9 \\ud83d\\ude00 \\n tab\\t q\\" s\\\\ sl\\/"}\n' > s.json
python3 - <<'EOF'
import json
text = json.load(open("s.json"))["e"]
print("python len:", len(text))
EOF
node -e '
const text = JSON.parse(require("fs").readFileSync("s.json", "utf8")).e;
console.log("node .length:", text.length);
console.log("node code points:", [...text].length);
'
