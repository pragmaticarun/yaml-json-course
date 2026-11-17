#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf -- '- run: echo hello: world\n' > bad.yml
yamlcheck bad.yml || echo "(yamlcheck exit status $?)"
printf -- '- run: "echo hello: world"\n' > good.yml
yaml2json good.yml
