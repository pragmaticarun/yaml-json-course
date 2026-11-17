#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > service.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {"type": "string"},
    "port": {"type": "integer"}
  },
  "required": ["name", "port"],
  "additionalProperties": false
}
EOF
cat > svc.yaml <<'EOF'
name: api
port: "8080"
EOF
schema-check service.schema.json svc.yaml
