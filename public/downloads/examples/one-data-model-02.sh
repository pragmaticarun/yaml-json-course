#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > order.json <<'EOF'
{
  "id": 1042,
  "customer": {"name": "Ada", "email": "ada@example.com"},
  "items": [
    {"sku": "A-1", "qty": 2},
    {"sku": "B-7", "qty": 1}
  ],
  "paid": true
}
EOF
json2yaml order.json | tee order.yaml
echo "---- back to JSON, compared with jq -S (sorted keys) ----"
yaml2json order.yaml | jq -S . > round.json
jq -S . order.json > original.json
diff original.json round.json && echo "round trip preserved the tree"
