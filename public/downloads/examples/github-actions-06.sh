#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > matrix.yml <<'EOF'
name: build
on: push
jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [20, 22]
    steps:
      - run: node --version
EOF
yaml2json matrix.yml | jq -c '.jobs.build.strategy.matrix'
cat > mini.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["on", "jobs"],
  "properties": {
    "jobs": {
      "type": "object",
      "minProperties": 1,
      "additionalProperties": {
        "type": "object",
        "required": ["runs-on"],
        "properties": {
          "steps": {
            "type": "array",
            "items": {
              "type": "object",
              "anyOf": [{"required": ["uses"]}, {"required": ["run"]}]
            }
          }
        }
      }
    }
  }
}
EOF
schema-check mini.schema.json matrix.yml
printf 'on: push\njobs:\n  t:\n    steps:\n      - name: nothing\n' > broken.yml
schema-check mini.schema.json broken.yml || true
