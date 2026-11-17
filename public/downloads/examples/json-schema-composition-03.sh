#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > endpoint.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"scheme": {"enum": ["http", "https"]}},
  "required": ["scheme"],
  "if": {"properties": {"scheme": {"const": "https"}}},
  "then": {"required": ["cert"]}
}
EOF
printf 'scheme: http\n'              > plain.yaml
printf 'scheme: https\ncert: a.pem\n' > secure.yaml
printf 'scheme: https\n'             > nocert.yaml
schema-check endpoint.schema.json plain.yaml secure.yaml nocert.yaml
