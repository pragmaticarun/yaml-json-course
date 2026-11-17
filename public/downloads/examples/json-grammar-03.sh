#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > strict.py <<'EOF'
import json, sys

def reject(name):
    raise ValueError(f"{name} is not valid JSON")

text = sys.argv[1]
print("default:", json.loads(text))
print("strict: ", json.loads(text, parse_constant=reject))
EOF
python3 strict.py '{"ratio": NaN}' 2>&1 | grep -E '^(default|strict|ValueError)'
