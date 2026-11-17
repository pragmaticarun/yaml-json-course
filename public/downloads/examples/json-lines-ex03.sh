#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"a":1}\noops\n{"a":3}\n' > check.jsonl
python3 - <<'EOF'
import json
for number, line in enumerate(open("check.jsonl"), start=1):
    try:
        json.loads(line)
    except json.JSONDecodeError:
        print("bad line:", number)
EOF
