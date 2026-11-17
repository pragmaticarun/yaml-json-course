#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > quote.yml <<'EOF'
env:
  PLAIN: ${{ secrets.TOKEN }}
  FROM_BRACE: "{{ not.an.expression }}"
  GLOB: "*.js"
  RATIO: "3:1"
  BRANCHES: ['*', 'release/**']
EOF
yaml2json quote.yml
echo "--- the same glob, unquoted ---"
printf 'files: *.js\n' > unquoted-glob.yml
yaml2json unquoted-glob.yml || true
echo "--- braces at the start of a value, unquoted ---"
printf 'x: {{ a.b }}\n' > unquoted-brace.yml
yaml2json unquoted-brace.yml 2>/dev/null
