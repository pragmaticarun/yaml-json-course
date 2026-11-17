#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > def.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"port": {"type": "integer", "default": 8080}},
  "required": ["port"]
}
EOF
echo '{}' > empty.json
schema-check def.schema.json empty.json
