#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
python3 - <<'EOF'
import json
from decimal import Decimal

text = '{"price": 1.10, "qty": 3}'
print("default:     ", json.loads(text))
print("with Decimal:", json.loads(text, parse_float=Decimal))
EOF
