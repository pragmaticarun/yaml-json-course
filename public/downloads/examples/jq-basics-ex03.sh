#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
who=Ada
echo '[{"name":"Ada","age":36},{"name":"Bo","age":29}]' > ages.json
jq --arg name "$who" '.[] | select(.name == $name) | .age' ages.json
