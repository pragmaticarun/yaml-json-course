#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'a: &x 1\nb: *x\nc: &x 2\nd: *x\n' | yaml2json | jq -c .
