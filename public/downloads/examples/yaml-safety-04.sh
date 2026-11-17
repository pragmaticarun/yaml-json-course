#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'role: user\nrole: admin\n' > dup.yaml
printf '{"role": "user", "role": "admin"}\n' > dup.json
echo "== YAML, yamlcheck"
yamlcheck dup.yaml || true
echo "== JSON text, read as YAML"
yamlcheck dup.json || true
echo "== JSON text, jq"
jq -c . dup.json
