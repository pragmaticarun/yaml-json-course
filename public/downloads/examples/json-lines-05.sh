#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > two.jsonl <<'EOF'
{"a":1}
{"a":2}
EOF
echo "python:"
python3 -c 'import json; json.load(open("two.jsonl"))' 2>&1 | tail -1 || true
echo "node:"
node -e 'JSON.parse(require("fs").readFileSync("two.jsonl","utf8"))' 2>&1 | grep -m1 SyntaxError || true
echo "split and parse in node:"
node -e '
const lines = require("fs").readFileSync("two.jsonl", "utf8").split("\n").filter(Boolean);
console.log(lines.map((line) => JSON.parse(line).a));
'
