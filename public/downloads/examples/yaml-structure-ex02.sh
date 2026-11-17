#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'steps:\n  - build\n  - test\n' > a.yaml
printf 'steps:\n- build\n- test\n' > b.yaml
yaml2json a.yaml > a.json
yaml2json b.yaml > b.json
cmp a.json b.json && echo "identical"
