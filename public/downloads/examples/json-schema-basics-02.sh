#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > service.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {"type": "string", "minLength": 1},
    "port": {"type": "integer", "minimum": 1, "maximum": 65535},
    "env":  {"enum": ["dev", "staging", "prod"]}
  },
  "required": ["name", "port"],
  "additionalProperties": false
}
EOF
cat > bad.json <<'EOF'
{"port": 70000, "env": "production", "colour": "blue"}
EOF
schema-check service.schema.json bad.json
