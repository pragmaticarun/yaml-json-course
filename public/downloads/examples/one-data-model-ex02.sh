#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > steps.yaml <<'EOF'
steps:
  - name: checkout
    uses: actions/checkout@v4
  - name: test
  run: npm test
EOF
yamlcheck steps.yaml || echo "(yamlcheck exit status $?)"
sed -i 's/^  run:/    run:/' steps.yaml
yaml2json steps.yaml
