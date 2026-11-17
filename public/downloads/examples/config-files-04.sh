#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > compose.yaml <<'EOF'
services:
  web:
    image: nginx:1.27
    ports:
      - "8080:80"
    environment:
      DEBUG: "false"
      WORKERS: 4
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: example
EOF
yaml2json compose.yaml | jq -c '.services | to_entries[] | {name: .key, image: .value.image}'
yaml2json compose.yaml | jq -c '.services.web | {ports, debug_type: (.environment.DEBUG | type), workers_type: (.environment.WORKERS | type)}'
