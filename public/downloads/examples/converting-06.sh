#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > a.json <<'EOF'
{"b": [1, 2], "a": {"y": 1, "x": 2}}
EOF
cat > b.yaml <<'EOF'
a:
  x: 2
  y: 1
b: [1, 2]
EOF
yaml2json b.yaml | jq -S . > b.canonical
jq -S . a.json > a.canonical
diff a.canonical b.canonical && echo "same tree"
echo "--- a real difference ---"
echo '{"a": {"x": 2, "y": 1}, "b": [2, 1]}' | jq -S . > c.canonical
diff a.canonical c.canonical || true
