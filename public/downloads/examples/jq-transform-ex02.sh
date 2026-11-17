#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"name":"app","port":80,"env":"prod","debug":false}' > s.json
jq -c 'to_entries | map(select(.value | type == "string")) | from_entries' s.json
