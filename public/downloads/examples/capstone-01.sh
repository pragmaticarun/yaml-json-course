#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > services.yaml <<'EOF'
version: 1
sizes:
  small: &small {cpu: 1, memory_mb: 256}
  large: &large {cpu: 4, memory_mb: 2048}
services:
  - {name: api,    port: 8080, env: prod, replicas: 3, resources: *large}
  - {name: worker, port: 9090, env: prod, replicas: 2, resources: *small}
  - {name: docs,   port: 8000, env: dev,  replicas: 1, resources: *small}
EOF

cat > services.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "resources": {
      "type": "object",
      "properties": {
        "cpu": {"type": "integer", "minimum": 1},
        "memory_mb": {"type": "integer", "minimum": 64}
      },
      "required": ["cpu", "memory_mb"],
      "additionalProperties": false
    },
    "service": {
      "type": "object",
      "properties": {
        "name": {"type": "string", "pattern": "^[a-z][a-z0-9-]*$"},
        "port": {"type": "integer", "minimum": 1, "maximum": 65535},
        "env": {"enum": ["dev", "staging", "prod"]},
        "replicas": {"type": "integer", "minimum": 1},
        "resources": {"$ref": "#/$defs/resources"}
      },
      "required": ["name", "port", "env", "replicas", "resources"],
      "additionalProperties": false
    }
  },
  "type": "object",
  "properties": {
    "version": {"const": 1},
    "sizes": {"type": "object", "additionalProperties": {"$ref": "#/$defs/resources"}},
    "services": {"type": "array", "minItems": 1, "items": {"$ref": "#/$defs/service"}}
  },
  "required": ["version", "services"],
  "additionalProperties": false
}
EOF

schema-check services.schema.json services.yaml
echo "--- summary by environment ---"
yaml2json services.yaml | jq -r '
  .services | group_by(.env)[]
  | {env: .[0].env,
     services: length,
     replicas: (map(.replicas) | add),
     memory_mb: (map(.replicas * .resources.memory_mb) | add)}
  | "\(.env): \(.services) services, \(.replicas) replicas, \(.memory_mb) MB"'
