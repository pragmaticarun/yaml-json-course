#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '%%YAML 1.2\n---\na: no\n' > v12.yaml
printf '%%YAML 1.1\n---\na: no\n' > v11.yaml
printf '%%YAML 1.3\n---\na: 1\n' > v13.yaml
echo "== declared 1.2"; yaml2json v12.yaml | jq -c .
echo "== declared 1.1"; yaml2json v11.yaml | jq -c .
echo "== declared 1.3"; yamlcheck v13.yaml
