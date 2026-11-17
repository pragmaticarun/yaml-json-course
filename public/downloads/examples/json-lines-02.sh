#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > log.jsonl <<'EOF'
{"t":1,"lvl":"info","msg":"start"}
{"t":2,"lvl":"error","msg":"boom"}
not json
{"t":4,"lvl":"info","msg":"end"}
EOF
jq -c . log.jsonl 2> err.txt || echo "(jq exit status $?)"
echo "--- stderr"
cat err.txt
echo "--- slurp"
jq -s -c . log.jsonl 2> err2.txt || echo "(jq exit status $?)"
cat err2.txt
