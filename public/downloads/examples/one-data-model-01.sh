#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > service.json <<'EOF'
{"name": "api", "port": 8080, "tags": ["web", "public"], "tls": null, "debug": false}
EOF

cat > service.yaml <<'EOF'
name: api
port: 8080
tags:
  - web
  - public
tls: null
debug: false
EOF

cat > service-flow.yaml <<'EOF'
{name: api, port: 8080, tags: [web, public], tls: null, debug: false}
EOF

yaml2json service.yaml > a.json
yaml2json service-flow.yaml > b.json
yaml2json service.json > c.json
cat a.json
cmp a.json b.json && echo "block style and flow style: same tree"
cmp a.json c.json && echo "YAML block style and the JSON file: same tree"
