#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > log.jsonl <<'EOF'
{"t":1,"lvl":"info","msg":"start"}
{"t":2,"lvl":"error","msg":"boom"}
not json
{"t":4,"lvl":"info","msg":"end"}
EOF
python3 - <<'EOF'
import json

with open("log.jsonl") as handle:
    for number, line in enumerate(handle, start=1):
        line = line.strip()
        if not line:
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError as err:
            print(f"line {number}: skipped ({err})")
            continue
        print(f"line {number}: {record['lvl']}")
EOF
