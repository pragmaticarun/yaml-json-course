#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > orders.json <<'EOF'
[{"id":1,"cust":"ada","total":30,"items":["a","b"]},
 {"id":2,"cust":"bo","total":15,"items":["c"]},
 {"id":3,"cust":"ada","total":55.5,"items":[]},
 {"id":4,"cust":"cy","total":10,"items":["a"]}]
EOF
echo "--- reshape each order"
jq -c '.[] | {id, customer: .cust, n: (.items | length)}' orders.json
echo "--- sum of totals";   jq 'map(.total) | add' orders.json
echo "--- ids over 12";     jq -c 'map(select(.total > 12)) | map(.id)' orders.json
echo "--- all items";       jq -c '[.[] | .items[]]' orders.json
echo "--- text";            jq -r '.[] | "\(.id): \(.cust) owes \(.total)"' orders.json
