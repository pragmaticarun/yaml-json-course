#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > log.jsonl <<'EOF'
{"t":1,"lvl":"info","msg":"start"}
{"t":2,"lvl":"error","msg":"boom"}
{"t":3,"lvl":"info","msg":"end"}
EOF
echo "--- one line per record, errors only"
jq -c 'select(.lvl == "error")' log.jsonl
echo "--- a column of messages"
jq -r '.msg' log.jsonl
echo "--- collect everything with -s"
jq -s -c '{records: length, levels: (map(.lvl) | unique)}' log.jsonl
echo "--- shell tools still work"
grep -c error log.jsonl
wc -l < log.jsonl
