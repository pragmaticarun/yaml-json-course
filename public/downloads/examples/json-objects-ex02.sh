#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"nickname": null}' > nick.json
jq -c '[has("nickname"), (.nickname == null), has("email")]' nick.json
