#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > t.yaml <<'EOF'
countries: [GB, NO, DE]
switches: [yes, no, on, off, y, n]
octal_looking: 010
explicit_octal: 0o10
duration: 1:30
version: 3.10
EOF
echo "== YAML 1.2 (default)"
yaml2json t.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 t.yaml | jq -c .
