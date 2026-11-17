#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > check.sh <<'EOF'
#!/usr/bin/env bash
# usage: check.sh schema.json services.yaml
schema=$1; file=$2; status=0

yamlcheck "$file" || exit 1
yaml2json "$file" > /dev/null || exit 1
schema-check "$schema" "$file" || status=1

dups=$(yaml2json "$file" | jq -r '[.services[]?.port] | group_by(.)[] | select(length > 1) | .[0]')
for port in $dups; do
  echo "$file: port $port is used by more than one service"
  status=1
done
exit $status
EOF

cat > schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "services": {"type": "array", "items": {
      "type": "object",
      "properties": {"name": {"type": "string"}, "port": {"type": "integer"}},
      "required": ["name", "port"], "additionalProperties": false}}
  },
  "required": ["services"]
}
EOF

cat > good.yaml <<'EOF'
services:
  - {name: api, port: 8080}
  - {name: docs, port: 8000}
EOF
cat > clash.yaml <<'EOF'
services:
  - {name: api, port: 8080}
  - {name: docs, port: 8080}
EOF
cat > invalid.yaml <<'EOF'
services:
  - {name: api, port: "8080", colour: blue}
EOF
printf 'services:\n  - name: api\n   port: 8080\n' > malformed.yaml

for f in good clash invalid malformed; do
  echo "=== $f.yaml"
  bash check.sh schema.json $f.yaml && echo "PASS" || echo "FAIL (exit $?)"
done
