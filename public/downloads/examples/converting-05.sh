#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > strings.json <<'EOF'
{"country": "no", "switch": "on", "mode": "010", "ratio": "1:30", "flag": "true", "version": "3.10"}
EOF
json2yaml strings.json | tee strings.yaml
echo "--- read as YAML 1.2 ---"
yaml2json strings.yaml
echo "--- read as YAML 1.1 ---"
yaml2json --yaml-1.1 strings.yaml
