#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > tsconfig.json <<'EOF'
{
  // compile for modern Node
  "compilerOptions": {
    "target": "ES2022",
    "strict": true,
  },
}
EOF
echo "--- jq ---"
jq . tsconfig.json || true
echo "--- JSON.parse ---"
node -e 'try { JSON.parse(require("fs").readFileSync("tsconfig.json", "utf8")) } catch (e) { console.error(e.message); process.exit(1) }'
