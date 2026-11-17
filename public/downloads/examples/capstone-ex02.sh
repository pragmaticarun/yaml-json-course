#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > m.yaml <<'EOF'
small: &small {cpu: 1, memory_mb: 256}
svc:
  <<: *small
  name: worker
EOF
echo "--- default ---"
yaml2json m.yaml | jq -c .svc
echo "--- 1.1 ---"
yaml2json --yaml-1.1 m.yaml | jq -c .svc
cat > r.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"svc": {"type": "object",
    "properties": {"name": {"type": "string"}, "cpu": {"type": "integer"}},
    "required": ["name", "cpu"], "additionalProperties": false}}
}
EOF
schema-check r.schema.json m.yaml || echo "(exit status $?)"
