#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"limit":10,"limit":20,"limit":30}' > l.json
jq -c . l.json
yamlcheck l.json || echo "(exit status $?)"
