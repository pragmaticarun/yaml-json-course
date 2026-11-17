#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'on: push\nname: ci\n' > wf.yaml
echo "== YAML 1.2"
yaml2json wf.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 wf.yaml | jq -c .
