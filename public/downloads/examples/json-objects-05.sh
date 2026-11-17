#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"a":{},"b":[]}' > empty.json
jq -c '[(.a|length), (.b|length), (.a == .b), (.a == null)]' empty.json
jq -c '{"a": null} | del(.a)' empty.json
