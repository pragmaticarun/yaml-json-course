#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"answer": "yes", "region": "no"}' | json2yaml > raw.yaml
cat raw.yaml
echo "--- 1.1 read of the raw file ---"
yaml2json --yaml-1.1 raw.yaml
printf 'answer: "yes"\nregion: "no"\n' > safe.yaml
echo "--- 1.1 read of the quoted file ---"
yaml2json --yaml-1.1 safe.yaml
