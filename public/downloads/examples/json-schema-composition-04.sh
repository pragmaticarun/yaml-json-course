#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > closed.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "allOf": [
    {"properties": {"name": {"type": "string"}}},
    {"properties": {"port": {"type": "integer"}}}
  ],
  "additionalProperties": false
}
EOF
cat > open.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "allOf": [
    {"properties": {"name": {"type": "string"}}},
    {"properties": {"port": {"type": "integer"}}}
  ],
  "unevaluatedProperties": false
}
EOF
printf 'name: api\nport: 80\n'            > fine.yaml
printf 'name: api\nport: 80\nextra: 1\n'  > extra.yaml
echo "--- additionalProperties"
schema-check closed.schema.json fine.yaml extra.yaml || true
echo "--- unevaluatedProperties"
schema-check open.schema.json fine.yaml extra.yaml
