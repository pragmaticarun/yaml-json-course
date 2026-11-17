#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > schema.json <<'EOF'
{
  "type": "object",
  "required": ["role", "port"],
  "properties": {
    "role": {"enum": ["user", "admin"]},
    "port": {"type": "integer", "minimum": 1, "maximum": 65535}
  },
  "additionalProperties": false
}
EOF
printf 'role: user\nport: 8080\n' > good.yaml
printf 'role: root\nport: "8080"\nextra: true\n' > bad.yaml
schema-check schema.json good.yaml bad.yaml || echo "(exit status $?)"
