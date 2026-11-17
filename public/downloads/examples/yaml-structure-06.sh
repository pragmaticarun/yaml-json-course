#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'a:\n  - 1\n   - 2\n' > quiet.yaml
yamlcheck quiet.yaml
yaml2json quiet.yaml | jq -c .
