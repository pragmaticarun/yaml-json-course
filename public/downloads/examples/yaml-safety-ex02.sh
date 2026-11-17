#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'timeout: 5\nretries: 3\ntimeout: 60\n' > cfg.yaml
yamlcheck cfg.yaml || echo "yamlcheck exit $?"
yaml2json cfg.yaml || echo "yaml2json exit $?"
