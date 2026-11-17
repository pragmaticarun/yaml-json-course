#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > ci.yml <<'EOF'
name: ci
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install
        run: npm ci
      - name: Test
        run: npm test
EOF
yaml2json ci.yml | jq -c '{name, on, jobs: (.jobs | keys), steps: (.jobs.test.steps | length)}'
yaml2json ci.yml | jq -c '.jobs.test.steps[]'
