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
echo "--- skip bad lines"
jq -R -c 'fromjson? | .msg' log.jsonl
echo "--- report bad lines in the output"
jq -R -c 'try fromjson catch "bad: \(.)"' log.jsonl
