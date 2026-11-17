#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > team.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "version": {"const": 1},
    "slug":    {"type": "string", "pattern": "^[a-z][a-z0-9-]*$"},
    "contact": {"type": "string", "format": "email"},
    "members": {"type": "array", "items": {"type": "string"}, "minItems": 2, "uniqueItems": true}
  },
  "required": ["version", "slug", "members"]
}
EOF
cat > team.yaml <<'EOF'
version: 2
slug: Platform Team
contact: not-an-email
members: [ada]
EOF
schema-check team.schema.json team.yaml
