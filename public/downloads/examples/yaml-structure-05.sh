#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf 'a:\n\tb: 1\n' > tab.yaml
printf 'a:\n  b: 1\n c: 2\n' > align.yaml
printf 'a:\n   - 1\n  - 2\n' > deeper.yaml
for f in tab align deeper; do
  echo "== $f.yaml"
  yamlcheck $f.yaml || true
done
