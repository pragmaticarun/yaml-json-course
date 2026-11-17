#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
text=$(printf 'He said "stop"\nnow')
jq -n -c --arg msg "$text" '{msg: $msg}'
