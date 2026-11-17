#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > log.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "level": {"enum": ["debug", "info", "warn", "error"]},
    "retries": {"type": "integer", "minimum": 0, "maximum": 5}
  }
}
EOF
printf 'level: trace\nretries: 9\n' > log.yaml
schema-check log.schema.json log.yaml || echo "(exit status $?)"
