#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > package.json <<'EOF'
{
  "name": "demo",
  // the entry point
  "main": "index.js",
}
EOF
node -e 'try { JSON.parse(require("fs").readFileSync("package.json", "utf8")) } catch (e) { console.error(e.message); process.exit(1) }'
