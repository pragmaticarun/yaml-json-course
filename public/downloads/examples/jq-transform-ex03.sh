#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"name":"app","version":"1.0.0"}' > package.json
jq '.version = "1.0.1"' package.json > package.json.tmp && mv package.json.tmp package.json
cat package.json
