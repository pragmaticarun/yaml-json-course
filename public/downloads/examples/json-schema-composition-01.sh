#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > pair.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "port": {"type": "integer", "minimum": 1, "maximum": 65535}
  },
  "type": "object",
  "properties": {
    "listen": {"$ref": "#/$defs/port"},
    "admin":  {"$ref": "#/$defs/port"}
  },
  "required": ["listen"]
}
EOF
printf 'listen: 8080\nadmin: 99999\n' > pair.yaml
schema-check pair.schema.json pair.yaml
