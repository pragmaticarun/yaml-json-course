#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > styles.yaml <<'EOF'
plain: hello world
single: 'it''s fine'
double: "tab\there, caf\u00e9, \x41"
single_backslash: 'no\tescape here'
EOF
yaml2json styles.yaml
