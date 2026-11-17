#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > source.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "oneOf": [
    {"type": "object", "required": ["url"]},
    {"type": "object", "required": ["path"]}
  ]
}
EOF
echo '{"url": "https://example.com"}'                > url.json
echo '{"url": "https://example.com", "path": "/tmp"}' > both.json
echo '{}'                                            > neither.json
schema-check source.schema.json url.json both.json neither.json
