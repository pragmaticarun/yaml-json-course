#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > notify.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "anyOf": [{"required": ["email"]}, {"required": ["phone"]}]
}
EOF
echo '{"email": "a@example.com"}' > e.json
echo '{"email": "a@example.com", "phone": "555"}' > b.json
echo '{}' > n.json
schema-check notify.schema.json e.json b.json n.json || echo "(exit status $?)"
