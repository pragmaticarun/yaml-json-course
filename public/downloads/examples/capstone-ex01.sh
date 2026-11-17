#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > s.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "env": {"enum": ["dev", "prod"]},
    "replicas": {"type": "integer"}
  },
  "required": ["env", "replicas"],
  "if": {"properties": {"env": {"const": "prod"}}},
  "then": {"properties": {"replicas": {"type": "integer", "minimum": 2}}}
}
EOF
echo '{"env": "prod", "replicas": 2}' > ok.json
echo '{"env": "dev", "replicas": 1}' > dev.json
echo '{"env": "prod", "replicas": 1}' > bad.json
schema-check s.json ok.json dev.json bad.json || echo "(exit status $?)"
