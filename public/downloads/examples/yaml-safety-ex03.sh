#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'count: lots\n' > req.yaml
echo '{"type":"object","properties":{"count":{"type":"integer"}}}' > req.schema.json
yamlcheck req.yaml
schema-check req.schema.json req.yaml || echo "(exit status $?)"
