#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > flow.yml <<'EOF'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: make
  deploy:
    needs: [build]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: make deploy
EOF
yaml2json flow.yml | jq -c '.jobs.deploy | {needs, "if": .["if"], type_of_if: (.["if"] | type)}'
