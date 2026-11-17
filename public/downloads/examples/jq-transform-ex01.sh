#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '[{"cust":"ada"},{"cust":"bo"},{"cust":"ada"}]' > c.json
jq -c 'group_by(.cust) | map({(.[0].cust): length}) | add' c.json
