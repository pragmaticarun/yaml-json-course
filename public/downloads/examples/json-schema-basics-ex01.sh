#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > s.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"port": {"type": "integer"}},
  "required": ["port"],
  "additionalProperties": false
}
EOF
echo '{"port": 80}' > ok.json
echo '{"prot": 80}' > typo.json
schema-check s.json ok.json typo.json || echo "(exit status $?)"
