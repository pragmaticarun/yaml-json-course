#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > items.yaml <<'EOF'
- name: a
  size: 1
-
  name: b
  size: 2
EOF
yaml2json items.yaml | jq -c .
echo "---- a sequence directly inside a sequence ----"
printf -- '- - 1\n  - 2\n- - 3\n' | yaml2json | jq -c .
