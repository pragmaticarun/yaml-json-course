#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"e":"caf\\u00e9 \\ud83d\\ude00 \\n tab\\t q\\" s\\\\ sl\\/"}\n' > s.json
python3 - <<'EOF'
import json
data = json.load(open("s.json"))
print(json.dumps(data))
print(json.dumps(data, ensure_ascii=False))
EOF
