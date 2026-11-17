#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > orders.json <<'EOF'
[{"id":1,"cust":"ada","total":30},{"id":2,"cust":"bo","total":15},
 {"id":3,"cust":"ada","total":55.5},{"id":4,"cust":"cy","total":10}]
EOF
echo "--- per customer"
jq -c 'group_by(.cust) | map({cust: .[0].cust, orders: length, sum: (map(.total) | add)})' orders.json
echo "--- same totals with reduce"
jq -c 'reduce .[] as $o ({}; .[$o.cust] += $o.total)' orders.json
echo "--- biggest first"
jq -c 'sort_by(-.total) | map(.id)' orders.json
echo "--- add on one-key objects does NOT sum"
jq -c 'map({(.cust): .total}) | add' orders.json
