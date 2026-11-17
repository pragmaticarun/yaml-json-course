#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > n.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {"name": {"type": "string", "pattern": "^[a-z]+$"}},
  "type": "object",
  "properties": {
    "first": {"$ref": "#/$defs/name"},
    "last":  {"$ref": "#/$defs/name"}
  }
}
EOF
printf 'first: ada\nlast: Lovelace\n' > n.yaml
schema-check n.schema.json n.yaml || echo "(exit status $?)"
