#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo "node:"
node -e 'console.log(0.1 + 0.2); console.log(2**53 + 1); console.log(Number.MAX_SAFE_INTEGER)'
echo "python:"
python3 -c 'print(0.1 + 0.2); print(2**53 + 1); print(float(2**53 + 1))'
echo "jq:"
jq -n -c '[0.1 + 0.2, 9007199254740993 + 0]'
