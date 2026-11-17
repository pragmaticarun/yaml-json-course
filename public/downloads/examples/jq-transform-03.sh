#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"a": 1, "b": 2}' > kv.json
echo "--- to_entries";    jq -c 'to_entries' kv.json
echo "--- filter by value"; jq -c 'to_entries | map(select(.value > 1)) | from_entries' kv.json
echo "--- with_entries";  jq -c 'with_entries(.value += 10)' kv.json
echo "--- map_values";    jq -c 'map_values(. * 2)' kv.json
