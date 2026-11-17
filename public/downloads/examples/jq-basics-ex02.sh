#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '[{"name":"Ada"},{"name":"Bo","nick":"bo"}]' > nicks.json
jq -r '.[] | .nick // .name' nicks.json
