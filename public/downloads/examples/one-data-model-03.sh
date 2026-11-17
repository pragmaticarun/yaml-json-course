#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'name: api\n  port: 8080\n' > broken.yaml
yamlcheck broken.yaml
