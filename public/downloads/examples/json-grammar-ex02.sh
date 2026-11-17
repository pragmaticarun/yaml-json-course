#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > check.py <<'EOF'
import json, sys

def reject(name):
    raise ValueError(name)

try:
    json.load(sys.stdin, parse_constant=reject)
except ValueError as err:
    print(f"rejected: {err}")
    sys.exit(1)
print("ok")
EOF
echo '{"x": 1}' | python3 check.py
echo '{"x": NaN}' | python3 check.py || echo "(exit status $?)"
